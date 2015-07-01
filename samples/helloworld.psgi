
=head1 NAME

helloworld.psgi - simple demo using CGI::Ex::App and PSGI

=head1 SYNOPSIS

    plackup helloworld.psgi

=cut

use base 'CGI::Ex::App';

sub main_hash_swap {
    return {
	message	=> 'hello world',
        time    => time(),
    };
}

sub main_file_print { \'[% message %] - the current time is [% time %]' }

__PACKAGE__->to_app;
