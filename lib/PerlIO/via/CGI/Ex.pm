package PerlIO::via::CGI::Ex;

=head1 NAME

PerlIO::via::CGI::Ex - Keep using print instead of $cgix->print_body

=head1 SYNOPSIS

    require PerlIO::via::CGI::Ex;

    binmode(STDOUT, ':via(CGI::Ex)');

    my $app = CGI::Ex::App::PSGI->psgi_app('My::App');

=head1 DESCRIPTION

If you have a legacy L<CGI::Ex::App> app that prints to STDOUT instead of
using C<print_body> and you want to use the L<PSGI> handler, you can use this
PerlIO layer to make C<print> pass your output to the current L<CGI::Ex>
instance for you. This does have slightly more overhead than calling
C<print_body> directly, but it does the job.

=cut

use strict;
use CGI::Ex;

our $VERSION = '2.41';

sub PUSHED {
    my ($class, $mode, $fh) = @_;
    return bless \(my $dummy), $class;
}

sub WRITE {
    my ($obj, $buffer, $fh) = @_;
    if (my $cgix = $CGI::Ex::CURRENT) {
        $cgix->print_body($buffer);
        return length($buffer);
    }
    return 0;
}

1;
