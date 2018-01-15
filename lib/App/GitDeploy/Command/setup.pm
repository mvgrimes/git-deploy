package App::GitDeploy::Command::setup;

# ABSTRACT: Initialize the remote repo and deploy dir

use 5.012;
use strict;
use warnings;
use Path::Tiny;
use App::GitDeploy::SSH;
use Role::Tiny::With;
use Term::ANSIColor;
use File::Path;
use Try::Tiny;
use IO::Prompter;
use DDP;

use App::GitDeploy -command;
with 'App::GitDeploy::Role::Run';

our $VERSION = '1.15';

sub description { 'Initialize the remote repo and deploy dir' }

sub opt_spec {
    return (
        # [ "app|a=s",    "The app to deploy", { default => '.' } ],
        # [ "remote|r=s", "The remote repos",  { default => 'production' } ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->{dry_run} = $self->app->global_options->{dry_run};

    $self->_config_git;
    $self->app->validate_global_opts();

    return 1;
}

sub _config_git {
    my ($self) = @_;

    my $git = Git::Wrapper->new('.');

    while ( my ( $remote, $config ) = each %{ $self->app->config } ) {
        if ( !$config->remote_url ) {
            say "Remote $remote must be configured. Something like:";
            say '  ssh://user@example.com/srv/repos/myapp.git';
            my $remote_url = prompt( -in => *STDIN, 'url: ' );
            $git->RUN( 'remote', 'add', $remote, $remote_url );
        }

        if ( !$config->deploy_url ) {
            say "Remote $remote deploy dir must be configured. Something like:";
            say '  /srv/apps/myapp';
            my $deploy_path = prompt( -in => *STDIN, 'path: ' );
            $git->RUN( 'config', '--local', "remote.$remote.deploy",
                $deploy_path );
        }
    }
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $app     = $self->app->global_options->{app};
    my $remotes = $self->app->global_options->{remotes};
    $self->_setup_remote( $app, $_, $opt, $arg ) for @$remotes;
}

sub _setup_remote {
    my ( $self, $app, $remote, $opt, $arg ) = @_;
    say color('blue') . "Processing $remote" . color('reset');

    my $config = $self->app->config->{$remote};
    my $ssh = App::GitDeploy::SSH->new( uri => $config->remote_url );

    # TODO: should $ssh->run be converted into $self->run?
    say "Creating the deployment repos: @{[ $config->remote_url ]}";
    $ssh->run("git init --bare @{[ $config->remote_url->path ]}")
      unless $self->{dry_run};

    say "Creating the deployment work dit: @{[ $config->deploy_dir ]}";
    $ssh->run(
        "test -d @{[ $config->deploy_dir->path ]} || mkdir @{[ $config->deploy_dir->path ]}",
    ) unless $self->{dry_run};

    $self->_create_template( $app, $remote );
}

sub _create_template {
    my ( $self, $app, $remote ) = @_;

    mkpath sprintf( 'deploy/%s/%s', $app, $remote ), { verbose => 1 };

    my $pr_file = path( sprintf 'deploy/%s/%s/post-receive', $app, $remote );
    if ( !-e $pr_file ) {
        say "Creating [$pr_file]";
        $pr_file->spew(
            q{#!/bin/bash

function die { echo -ne '\033[31m'; echo $@; echo -ne '\033[0m'; exit 1; }

# logfile=log/deploy.log
# restart=tmp/restart.txt
# umask 002

git diff --quiet \
    || die "Changes to production files found. Aborting."
[ -z "$( git ls-files --exclude-standard --others )" ] \
    || die "Untracked files in $GIT_WORK_TREE. Aborting."

git checkout -f
        }
        );
    }
    $pr_file->chmod(0755);
}

1;

__END__

=pod

=head1 NAME

App::GitDeploy::Command::setup - Initialize the remote repo and deploy dir

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
