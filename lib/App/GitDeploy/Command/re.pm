package App::GitDeploy::Command::re;

use 5.012;
use strict;
use warnings;
use Moo;

extends 'App::GitDeploy::Command::go';

our $VERSION = '1.12';

around 'execute' => sub {
    my ( $orig, $self, $opt, $arg ) = ( shift, shift, shift, shift );
    $opt->{skip} = 1;
    $self->$orig( $opt, $arg, @_ );
};

1;

__END__

=pod

=head1 NAME

App::GitDeploy::Command::re

=head1 VERSION

version 1.12

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
