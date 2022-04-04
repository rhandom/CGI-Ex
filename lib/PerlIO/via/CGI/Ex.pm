package PerlIO::via::CGI::Ex;

=head1 NAME

PerlIO::via::CGI::Ex - Keep using print instead of $cgix->print_body

=head1 SYNOPSIS

    use PerlIO::via::CGI::Ex;

    binmode(STDOUT, ':via(CGI::Ex)');
    my $app = My::App->to_app;

=head1 DESCRIPTION

If you have a legacy L<CGI::Ex::App> app that prints to STDOUT instead of
using C<print_body> and you want to use L<PSGI>, you can use this PerlIO layer
to make C<print> pass your output to the current L<CGI::Ex> instance for you.
This does have slightly more overhead than calling C<print_body> directly, but
it does the job.

=cut

use strict;
use CGI::Ex;

our $VERSION = '999.99'; # VERSION

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
