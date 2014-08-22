package App::GitDeploy::Command::setup;

use strict;
use warnings;
use Path::Class;
use App::GitDeploy::SSH;
use App::GitDeploy::Config;
use File::Path;

use App::GitDeploy -command;

our $VERSION = '1.00';
our $config;

sub opt_spec {
    return (
        [ "app|a=s",    "The app to deploy", { default => '.' } ],
        [ "remote|r=s", "The remote repos",  { default => 'production' } ],
        [ "work|w=s",   "The work " ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    my $app    = $opt->{app};
    my $remote = $opt->{remote};

    $config = App::GitDeploy::Config->new( remote => $remote );

    $self->usage_error(
        qq{Remote $remote must be configured. Try 'git remote add $remote "user\@example.com:/srv/repos/myapp.git"'}
    ) unless $config->remote_url;
    $self->usage_error(
        qq{Remote $remote deploy dir must be configured. Try 'git --config --local remote.$remote.deploy "/srv/apps/myapp"'}
    ) unless $config->deploy_url;

    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $ssh = App::GitDeploy::SSH->new( uri => $config->remote_url );

    $ssh->run( "git init --bare @{[ $config->remote_url->path ]}", );
    $ssh->run( "mkdir @{[ $config->deploy_dir->path ]}", );

    mkpath sprintf 'deploy/%s/%s', $opt->{app}, $opt->{remote};
    mkpath sprintf 'deploy/%s/staging', $opt->{app};

    my $pr_file =
      file( sprintf 'deploy/%s/%s/post-receive', $opt->{app}, $opt->{remote} );
    $pr_file->spew(
        qq{#!/bin/bash

function die { echo $@; exit 1; }

# logfile=log/deploy.log
# restart=tmp/restart.txt
# umask 002

git diff --quiet || die "Changes to production files found. Aborting."
git ls-files -o  | grep . >/dev/null && die "Untracked files. Aborting."
git checkout -f master
        }
    );
    chmod 0755, $pr_file;

    return;
}

1;

