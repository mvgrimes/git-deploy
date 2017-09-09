package App::GitDeploy::Command::go;

# ABSTRACT: Execute the deployment

use 5.012;
use strict;
use warnings;
use Path::Class;
use Data::Printer;
use Path::Class qw(dir file);
use Role::Tiny::With;
use Term::ANSIColor;

use App::GitDeploy -command;
with 'App::GitDeploy::Role::Run';

our $VERSION = '1.13';

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

    my $config       = $self->app->validate_global_opts();
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

sub announce {
    my ( $self, $msg, $color ) = @_;
    $color //= 'blue';
    say color($color) . $msg . color('reset');
}

sub announce_and_run {
    my ( $self, $message, $run_opts ) = @_;
    $self->announce($message);
    $self->run($run_opts);
}

sub execute {
    my ( $self, $opt, $arg ) = @_;
    my $app    = $self->app->global_options->{app};
    my $remote = $self->app->global_options->{remote};

    my $prior = ( split /\s+/, `git show-ref refs/remotes/$remote/master` )[0];
    my $current = ( split /\s+/, `git show-ref refs/heads/master` )[0];
    my $post_receive =
      file("deploy/$app/$remote/post-receive")->cleanup->stringify;

    $self->announce_and_run(
        'before-deploy',
        {
            cmd       => "deploy/$app/$remote/before-deploy",
            if_exists => 1
        } ) if $opt->{'before-deploy'};

    $self->announce_and_run( 'pushing',
        { cmd => "git push --tags $remote master" } )
      if $opt->{push};

    $self->announce_and_run(
        'after-deploy',
        {
            cmd       => "deploy/$app/$remote/after-deploy",
            if_exists => 1
        } ) if $opt->{'after-deploy'};

    $self->announce_and_run(
        'post-received',
        {
            cmd => qq{pr=\$( mktemp -t git-deploy.XXXXXXX ) \\
                   && git show master:$post_receive > \$pr \\
                   && bash \$pr },
            host => $self->app->config->remote_url,
        } );

    $self->announce_and_run(
        'before-restart',
        {
            cmd       => "deploy/$app/$remote/before-restart $prior $current",
            host      => $self->app->config->deploy_url,
            if_exists => 1
        } ) if $opt->{'before-restart'};
    $self->announce_and_run(
        'restart',
        {
            cmd       => "deploy/$app/$remote/restart $prior $current",
            host      => $self->app->config->deploy_url,
            if_exists => 1
        } ) if $opt->{restart};
    $self->announce_and_run(
        'after-restart',
        {
            cmd       => "deploy/$app/$remote/after-restart $prior $current",
            host      => $self->app->config->deploy_url,
            if_exists => 1
        } ) if $opt->{'after-restart'};
}

1;

__END__

=pod

=head1 NAME

App::GitDeploy::Command::go

=head1 VERSION

version 1.13

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
