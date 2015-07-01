# -*- Mode: Perl; -*-

=head1 NAME

4_app_01_psgi.t - Check for the PSGI functionality of CGI::Ex::App.

=head1 NOTE

The PSGI support makes CGI::Ex::App as a whole much more testable because the
responses are simple data structures rather than streams.  We should add more
tests sometime, but here are some basic ones for now.

=cut

use Test::More tests => 5;
use strict;
use warnings;

SKIP: {
    skip("CGI/PSGI.pm not found", 5) if ! eval { require CGI::PSGI };
    {
        package App1;
        use base 'CGI::Ex::App';
        sub main_print { shift->run_hook('print_out', shift, 'hello world') }
        sub other_print { shift->run_hook('print_out', shift, 'other step') }
    }

    my $app1 = App1->to_app;
    ok(ref($app1) eq 'CODE', 'to_app returns a CODEREF');

    my $res1 = $app1->({
        SCRIPT_NAME => '/app1',
        PATH_INFO   => '/main',
    });
    is($res1->[0], 200, 'status is 200');
    my $res1_headers = {@{$res1->[1]}};
    ok(exists $res1_headers->{'Content-Type'}, 'is content_typed');
    ok(scalar grep { $_ eq 'hello world' } @{$res1->[2]}, 'main step body is correct');

    my $res2 = $app1->({
        SCRIPT_NAME => '/app1',
        PATH_INFO   => '/other',
    });
    ok(scalar grep { $_ eq 'other step' } @{$res2->[2]}, 'other step body is correct');
}

