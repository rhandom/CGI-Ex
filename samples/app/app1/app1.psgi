
=head1 NAME

app1 - Signup application using CGI::Ex::App

 * configuration comes from conf file
 * steps are in separate modules

=head1 SYNOPSIS

    plackup app1.psgi

=cut

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";

use App1;
use Plack::Builder;

# Use the IO layer shim because this sample still doesn't always use print_body yet.
use PerlIO::via::CGI::Ex;
binmode(STDOUT, ':via(CGI::Ex)');

builder {
    # Simply call the to_app method on any CGI::Ex::App to get a PSGI app.
    mount '/signup' => App1->to_app;

    # This is necessary because App1 hard codes path (see App1::js_uri_path).
    mount '/js.pl' => sub {
	my $env = shift;
	# This is how you can do PSGI with straight CGI::Ex.
	require CGI::Ex;
	require CGI::PSGI;
	my $cgix = CGI::Ex->new(object => CGI::PSGI->new($env));
	$cgix->print_js($env->{'PATH_INFO'});
	return $cgix->psgi_response;
    },

    # helper routes
    mount '/favicon.ico' => sub { [404, [], ['Not Found']] };
    mount '/' => sub { [302, [Location => '/signup'], []] };
}
