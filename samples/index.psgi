
=head1 NAME

index.psgi - Show a listing of available utilities in the samples directories.

=head1 DESCRIPTION

As a PSGI app, it falls upon us to do some of the things that apache would
handle for us, like finding and running scripts. Here we use L<Plack::Builder>
and call upon F<index.cgi> to help us mount as many samples as we can so that
they can be linked to.

=cut

use warnings;
use strict;

use CGI::Ex::App;

use FindBin qw($Bin);
use Plack::Builder;

builder {

    my $index_app = CGI::Ex::App->repackage("$Bin/index.cgi");

    # run the hash_swap from index.cgi once to get the list of apps we may be able mount
    my $hash = $index_app->new(script_name => '')->run_hook('hash_swap', 'main');
    for my $app_path (keys %{$hash->{'app' || {}}}, keys %{$hash->{'bench'} || {}}) {
        $app_path =~ s!^/!!;
        my $real_path = "$Bin/$app_path";
        next if $real_path !~ /(?:pl|cgi)$/ || !-r $real_path;

        # if it looks like a CGI::Ex::App script, try to repackage it as a native app
        open(my $script, '<:utf8', $real_path) or die "Open '$real_path' failed ($!)";
        my $content = do { local $/ = undef; <$script> };
        close($script);
        if ($content =~ /->navigate/) {
            my $app = eval { CGI::Ex::App->repackage($real_path)->to_app };
            if ($app) {
                mount "/$app_path" => $app;
                print STDERR " * Mounted $app_path as a repackaged CGI::Ex::App script.\n";
                next;
            } else {
                warn "Loading $app_path failed: $@";
            }
        }

        # if all else fails, maybe we can just wrap the CGI script
        if (eval { require Plack::App::WrapCGI }) {
            my $app = eval { Plack::App::WrapCGI->new(script => $real_path)->to_app };
            if ($app) {
                mount "/$app_path" => $app;
                print STDERR " * Mounted $app_path as a wrapped CGI.\n";
            } else {
                print STDERR " * Skipped $app_path: $@.\n";
            }
        }
    }

    mount '/' => $index_app->to_app(script_name => '', name_module => 'index');

};

