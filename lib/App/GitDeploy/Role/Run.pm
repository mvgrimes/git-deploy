package App::GitDeploy::Role::Run;

# ABSTRACT: Role to provide local and remote run commands

use 5.012;
use strict;
use warnings;
use Try::Tiny;
use File::chdir;
use Term::ANSIColor;
use App::GitDeploy::SSH;
use IPC::Cmd ();
use Data::Printer;
use IPC::System::Simple qw(system systemx capture capturex);

use Role::Tiny;

our $VERSION = '1.15';

sub run {
    my ( $self, $opts ) = @_;

    if ( $opts->{'dry_run'} ) {
        say "   " . $opts->{cmd};
    } else {
        if ( exists $opts->{host} ) {
            $self->_remote_run($opts);
        } else {
            $self->_local_run($opts);
        }
    }
}

sub _remote_run {
    my ( $self, $opts ) = @_;

    my $config = $opts->{config};
    my $cmd    = qq{
        export GIT_DIR="@{[ $config->remote_url->path ]}";
        export GIT_WORK_TREE="@{[ $config->deploy_dir->path ]}";
        cd @{[ $config->deploy_dir->path ]};
        $opts->{cmd} };

    if ( $opts->{host}->scheme eq 'ssh' ) {
        my $ssh = App::GitDeploy::SSH->new( uri => $opts->{host} );

        if ( $opts->{if_exists} ) {
            my $cmd = ( split /\s+/, $opts->{cmd} )[0];
            my $test_cmd = qq{
                cd @{[ $opts->{host}->path ]};
                test -x $cmd };
            return unless $ssh->test($test_cmd);
        }

        $ssh->run($cmd)
          or die color('red')
          . "Error running '$cmd on remote'\n"
          . color('reset') . "\n";

    } else {
        local $CWD = $opts->{host}->path;

        die "Remote path doesn't appear to exist"
          unless -d $opts->{host}->path;

        local_run( { $opts, cmd => $cmd } );
    }

}

sub _local_run {
    my ( $self, $opts ) = @_;

    my $config = $opts->{config};
    my $buffer;

    if ( $opts->{if_exists} ) {
        my ( $cmd, undef ) = split / /, $opts->{cmd}, 2;
        return unless IPC::Cmd::can_run($cmd);
    }

    say color('grey12') . "running [$opts->{cmd}]" . color('reset');
    try {
        system( $opts->{cmd} );
    }
    catch {
        die color('red')
          . "Error running '$opts->{cmd}'\n"
          . $_ . "\n"
          . color('reset') . "\n";
    };
}

1;

__END__

=pod

=head1 NAME

App::GitDeploy::Role::Run - Role to provide local and remote run commands

=head1 VERSION

version 1.15

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/git-deploy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/git-deploy/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
