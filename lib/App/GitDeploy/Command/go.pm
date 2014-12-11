package App::GitDeploy::Command::go;

use 5.012;
use strict;
use warnings;
use Path::Class;
use Data::Printer;
use Path::Class qw(dir file);
use App::GitDeploy::SSH;
use App::GitDeploy::Config;
use Term::ANSIColor;

use App::GitDeploy -command;

our $VERSION = '1.08';
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

sub announce {
    my ( $self, $msg, $color ) = @_;
    $color //= 'blue';
    say color($color) . $msg . color('reset');
}

sub execute {
    my ( $self, $opt, $arg ) = @_;
    my $app    = $self->app->global_options->{app};
    my $remote = $self->app->global_options->{remote};

    my $prior = ( split /\s+/, `git show-ref refs/remotes/$remote/master` )[0];
    my $current = ( split /\s+/, `git show-ref refs/heads/master` )[0];

    $self->announce('before-deploy');
    $self->_run( { cmd => "deploy/$app/$remote/before-deploy", if_exists => 1 } );
    $self->announce('pushing');
    $self->_run( { cmd => "git push --tags $remote master" } );
    $self->announce('after-deploy');
    $self->_run( { cmd => "deploy/$app/$remote/after-deploy", if_exists => 1 } );

    my $post_receive =
      file("deploy/$app/$remote/post-receive")->cleanup->stringify;

    $self->announce('post-received');
    $self->_run( {
            cmd => qq{pr=\$( mktemp -t git-deploy.XXXXXXX ) \\
                   && git show master:$post_receive > \$pr \\
                   && bash \$pr },
            host => $config->remote_url,
    } );

    $self->announce('before-restart');
    $self->_run( {
        cmd       => "deploy/$app/$remote/before-restart $prior $current",
        host      => $config->deploy_url,
        if_exists => 1
    } );
    $self->announce('restart');
    $self->_run( {
        cmd       => "deploy/$app/$remote/restart $prior $current",
        host      => $config->deploy_url,
        if_exists => 1
    } );
    $self->announce('after-restart');
    $self->_run( {
        cmd       => "deploy/$app/$remote/after-restart $prior $current",
        host      => $config->deploy_url,
        if_exists => 1
    } );
}

1;

__END__

=pod

=head1 NAME

App::GitDeploy::Command::go

=head1 VERSION

version 1.08

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
