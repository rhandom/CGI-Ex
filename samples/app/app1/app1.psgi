
=head1 NAME

app1 - Signup application using CGI::Ex::App and CGI::Ex::App::PSGI

 * configuration comes from conf file
 * steps are in separate modules

=cut

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use CGI::Ex::App::PSGI;

CGI::Ex::App::PSGI->psgi_app('App1');
