package App::GitDeploy::Command::redeploy;

# ABSTRACT: ...

use strict;
use warnings;
use Path::Class;

use App::GitDeploy -command;

our $VERSION = '1.01';

sub opt_spec {
    # return ( [ "filename|f=s", "The filename and path of the package", ] );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    return;
}

1;

__END__

=pod

=head1 NAME

App::GitDeploy::Command::redeploy - ...

=head1 VERSION

version 1.01

=head1 DESCRIPTION

See L<App::EditorTools> for documentation.

=head1 NAME

App::EditorTools::Command::RenamePackageFromPath - Rename the Package Based on the Path of the File

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
