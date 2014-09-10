package App::GitDeploy::Command::redeploy;

# ABSTRACT: ...

use 5.012;
use strict;
use warnings;
use Path::Class;
use IPC::Cmd;
use Data::Printer;
use Path::Class qw(dir file);
use File::chdir;
use App::GitDeploy::SSH;
use App::GitDeploy::Config;

use App::GitDeploy -command;

our $VERSION = '1.03';
our $config;

sub opt_spec {
    return (
        # [ "app|a=s",    "The app to deploy", { default => '.' } ],
        # [ "remote|r=s", "The remote repos",  { default => 'production' } ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $config = $self->app->validate_global_opts();

    my $app          = $self->app->global_options->{app};
    my $remote       = $self->app->global_options->{remote};
    my $post_receive = "deploy/$app/$remote/post-receive";

    $self->usage_error("A valid app must be specificed")
      unless -d "deploy/$app/";
    $self->usage_error("$post_receive must be created")
      unless -e $post_receive;
    $self->usage_error("$post_receive must be executable")
      unless -x $post_receive;

    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;
    my $app    = $self->app->global_options->{app};
    my $remote = $self->app->global_options->{remote};

    # run( { cmd => "deploy/$app/$remote/before-deploy", if_exists => 1 } );
    # run( { cmd => "git push --tags $remote master" } );
    # run( { cmd => "deploy/$app/$remote/after-deploy",  if_exists => 1 } );

    my $post_receive =
      file("deploy/$app/$remote/post-receive")->cleanup->stringify;

    run( {
        cmd  => qq{eval "\$( git show master:$post_receive )"},
        host => $config->remote_url,
    } );

    run( {
        cmd       => "deploy/$app/$remote/before-restart",
        host      => $config->deploy_url,
        if_exists => 1
    } );
    run( {
        cmd       => "deploy/$app/$remote/restart",
        host      => $config->deploy_url,
        if_exists => 1
    } );
    run( {
        cmd       => "deploy/$app/$remote/after-restart",
        host      => $config->deploy_url,
        if_exists => 1
    } );
}

sub run {
    my ($opts) = @_;

    if ( exists $opts->{host} ) {
        remote_run($opts);
    } else {
        local_run($opts);
    }
}

sub remote_run {
    my ($opts) = @_;

    my $cmd = qq{
        export GIT_DIR="@{[ $config->remote_url->path ]}";
        export GIT_WORK_TREE="@{[ $config->deploy_dir->path ]}";
        cd @{[ $opts->{host}->path ]};
        $opts->{cmd} };

    if ( $opts->{host}->scheme eq 'ssh' ) {
        my $ssh = App::GitDeploy::SSH->new( uri => $opts->{host} );

        if ( $opts->{if_exists} ) {
            my $test_cmd = qq{
                cd @{[ $opts->{host}->path ]};
                test -x $opts->{cmd} };
            return unless $ssh->test($test_cmd);
        }

        $ssh->run($cmd);
    } else {
        local $CWD = $opts->{host}->path;

        die "Remote path doesn't appear to exist"
          unless -d $opts->{host}->path;

        local_run( { $opts, cmd => $cmd } );
    }

}

sub local_run {
    my ($opts) = @_;
    my $buffer;

    if ( $opts->{if_exists} ) {
        my ( $cmd, undef ) = split / /, $opts->{cmd}, 2;
        return unless IPC::Cmd::can_run($cmd);
    }

    IPC::Cmd::run(
        command => $opts->{cmd},
        verbose => 1,
        buffer  => \$buffer,
    ) or die "Error running '$opts->{cmd}'\n";
}


1;

__END__

=pod

=head1 NAME

App::GitDeploy::Command::redeploy - ...

=head1 VERSION

version 1.03

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
