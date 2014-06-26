package CGI::Ex::App::PSGI;

=head1 NAME

CGI::Ex::App::PSGI - Easily run your CGI::Ex::App as a PSGI app

=head1 SYNOPSIS

    # in app.psgi:

    use CGI::Ex::App::PSGI;
    CGI::Ex::App::PSGI->psgi_app('MyApp');

OR

    # in app.cgi:

    use base 'CGI::Ex::App';

    __PACKAGE__->navigate;
    exit;

    ...

    # and in app.psgi or elsewhere:

    use CGI::Ex::App::PSGI;
    CGI::Ex::App::PSGI->psgi_app_repackage('path/to/app.cgi');

=cut

use strict;
use Plack::Util;
use CGI::Ex;
use CGI::PSGI;

our $VERSION = '2.41';

sub psgi_app {
    my ($class, $app) = @_;

    Plack::Util::load_class($app);
    sub {
        my $env = shift;
        my $cgix = CGI::Ex->new(object => CGI::PSGI->new($env));

        if ($env->{'psgi.streaming'}) {
            sub {
                local $CGI::Ex::CURRENT = $cgix;
                local %ENV              = (%ENV, $class->cgi_environment($env));
                local *STDIN            = $env->{'psgi.input'};
                local *STDERR           = $env->{'psgi.errors'};

                $cgix->{psgi_responder} = shift;
                $app->new(
                    cgix        => $cgix,
                    script_name => $env->{SCRIPT_NAME},
                    path_info   => $env->{PATH_INFO},
                )->navigate->cgix->psgi_respond->close;
            };
        } else {
            local $CGI::Ex::CURRENT = $cgix;
            local %ENV              = (%ENV, $class->cgi_environment($env));
            local *STDIN            = $env->{'psgi.input'};
            local *STDERR           = $env->{'psgi.errors'};

            $app->new(cgix => $cgix)->navigate->cgix->psgi_response;
        }
    };
}

sub psgi_app_repackage {
    my ($class, $filepath) = @_;

    my $package = do {
        my $str = $filepath;
        $str =~ s|.*?([^/\\]+)\.pl$|$1|;
        $str =~ s|([^A-Za-z0-9\/_])|sprintf("_%2x",unpack("C",$1))|eg;
        $str =~ s|/(\d)|sprintf("/_%2x",unpack("C",$1))|eg;
        $str =~ s|[/_]|::|g;
        "CGI::Ex::App::PSGI::App::$str";
    };

    open(my $script, '<:utf8', $filepath) or die "Open '$filepath' failed ($!)";
    my $app = do { local $/ = undef; <$script> };
    close($script);

    my $eval = qq(# line 1 "$filepath"\npackage $package; sub app { $app });
    {
        my ($filepath, $package);
        eval("$eval; 1") or die $@;
    }
    my $package_filepath = $package;
    $package_filepath =~ s!::!/!g;
    $INC{"$package_filepath.pm"} = $filepath;

    return CGI::Ex::App::PSGI->psgi_app($package);
}

### Convert a PSGI environment into a CGI environment.
sub cgi_environment {
    my ($class, $env) = @_;

    my $environment = {
        GATEWAY_INTERFACE   => 'CGI/1.1',
        HTTPS               => $env->{'psgi.url_scheme'} eq 'https' ? 'ON' : 'OFF',
        SERVER_SOFTWARE     => "CGI-Ex-App-PSGI/$VERSION",
        REMOTE_ADDR         => '127.0.0.1',
        REMOTE_HOST         => 'localhost',
        map { $_ => $env->{$_} } grep { !/^psgix?\./ } keys %$env,
    };

    return wantarray ? %$environment : $environment;
}

1;
