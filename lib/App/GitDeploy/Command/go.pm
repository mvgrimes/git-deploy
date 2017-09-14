package App::GitDeploy::Command::go;

# ABSTRACT: Execute the deployment

use 5.012;
use strict;
use warnings;
use Path::Tiny;
use Data::Printer;
use Role::Tiny::With;
use Term::ANSIColor;
use Perl6::Junction qw(any);

use App::GitDeploy -command;
with 'App::GitDeploy::Role::Run';

our $VERSION = '1.14';

sub opt_spec {
    return (
        ## [ "skip|s", "Redeploy (ie, skip the push, etc)", { default => 0 } ], );
        [
            "before-deploy|b!",
            "Run the before-deploy hook (or no-*)",
            { default => 1 }
        ],
        [ "push!", "Push code to the deploy repo (or no-*)", { default => 1 } ],
        [
            "after-deploy!",
            "Run the after deploy hook (or no-*)",
            { default => 1 }
        ],
        [
            "before-restart!",
            "Run the before restart hook (or no-*)",
            { default => 1 }
        ],
        [ "restart!", "Run the restart hook (or no-*)", { default => 1 } ],
        [
            "after-restart!",
            "Run the after-restart hook (or no-*)",
            { default => 1 }
        ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    my $config  = $self->app->validate_global_opts();
    my $app     = $self->app->global_options->{app};
    my $remotes = $self->app->global_options->{remotes};
    $self->{dry_run} = $self->app->global_options->{dry_run};

    for my $remote (@$remotes) {
        my $post_receive = "deploy/$app/$remote/post-receive";

        $self->usage_error("A valid app must be specificed")
          unless -d "deploy/$app/";
        $self->usage_error("$post_receive must be created")
          unless -e $post_receive;
        $self->usage_error("$post_receive must be executable")
          unless -x $post_receive;
    }

    $self->{before_deploy_run} = [];

    return 1;
}

sub announce {
    my ( $self, $msg, $color ) = @_;
    say color( $color // 'magenta' ) . $msg . color('reset');
}

sub announce_and_run {
    my ( $self, $message, $run_opts ) = @_;
    $self->announce($message);
    $run_opts->{dry_run} = $self->{dry_run};
    $run_opts->{config}  = $self->app->config->{ $run_opts->{remote} };
    $self->run($run_opts);
}

sub execute {
    my ( $self, $opt, $arg ) = @_;
    my $app     = $self->app->global_options->{app};
    my $remotes = $self->app->global_options->{remotes};

    $self->_process_remote( $app, $_, $opt, $arg ) for @$remotes;
}

sub _process_remote {
    my ( $self, $app, $remote, $opt, $arg ) = @_;

    my $prior = ( split /\s+/, `git show-ref refs/remotes/$remote/master` )[0];
    my $current       = ( split /\s+/, `git show-ref refs/heads/master` )[0];
    my $post_receive  = path("deploy/$app/$remote/post-receive");
    my $before_deploy = path("deploy/$app/$remote/before-deploy");
    $prior //= '""';

    say color('blue') . "Processing $remote" . color('reset');
    if ( $opt->{before_deploy} && $self->_havent_run($before_deploy) ) {
        $self->announce_and_run(
            'before-deploy',
            {
                cmd       => "deploy/$app/$remote/before-deploy",
                remote    => $remote,
                if_exists => 1,
            } );
        push @{ $self->{before_deploy_run} }, $before_deploy->stat->ino;
    }

    $self->announce_and_run(
        'pushing',
        {
            cmd    => "git push --tags $remote master",
            remote => $remote,
        } ) if $opt->{push};

    $self->announce_and_run(
        'after-deploy',
        {
            cmd       => "deploy/$app/$remote/after-deploy",
            remote    => $remote,
            if_exists => 1
        } ) if $opt->{after_deploy};

    $self->announce_and_run(
        'post-received',
        {
            cmd => qq{pr=\$( mktemp -t git-deploy.XXXXXXX ) \\
                   && git show master:$post_receive > \$pr \\
                   && bash \$pr },
            remote => $remote,
            host   => $self->app->config->{$remote}->remote_url,
        } );

    $self->announce_and_run(
        'before-restart',
        {
            cmd       => "deploy/$app/$remote/before-restart $prior $current",
            host      => $self->app->config->{$remote}->deploy_url,
            remote    => $remote,
            if_exists => 1,
        } ) if $opt->{before_restart};
    $self->announce_and_run(
        'restart',
        {
            cmd       => "deploy/$app/$remote/restart $prior $current",
            host      => $self->app->config->{$remote}->deploy_url,
            remote    => $remote,
            if_exists => 1,
        } ) if $opt->{restart};
    $self->announce_and_run(
        'after-restart',
        {
            cmd       => "deploy/$app/$remote/after-restart $prior $current",
            host      => $self->app->config->{$remote}->deploy_url,
            remote    => $remote,
            if_exists => 1,
        } ) if $opt->{after_restart};
}

sub _havent_run {
    my ( $self, $file ) = @_;

    return unless $file->exists;

    my $inode     = $file->stat->ino;
    my $files_run = $self->{before_deploy_run};

    my $already_run = $inode == any(@$files_run);

    say color('yellow') . "Skipping $file, already run" . color('reset')
      if $already_run;

    return !$already_run;
}

1;

__END__

=pod

=head1 NAME

App::GitDeploy::Command::go - Execute the deployment

=head1 VERSION

version 1.14

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

This software is copyright (c) 2017 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
