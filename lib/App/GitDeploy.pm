package App::GitDeploy;

# ABSTRACT: Command line tool to deploy any application using git

use 5.012;
use strict;
use warnings;
use App::GitDeploy::Config;
use File::chdir;
use IPC::Cmd ();
use IPC::System::Simple qw(run runx capture capturex);

use App::Cmd::Setup -app;

our $VERSION = '1.08';
our $config;

sub global_opt_spec {
    return (
        [ "app|a=s",    "The app to deploy", { default => '.' } ],
        [ "remote|r=s", "The remote repos",  { default => 'production' } ],
    );
}

sub validate_global_opts {
    my ($self) = @_;

    $self->usage_error( "Must be run at the root of your git repo." )
      unless -e '.git';

    my $remote = $self->global_options->{remote};
    $config = App::GitDeploy::Config->new( remote => $remote );

    $self->usage_error( qq{Remote $remote must be configured.\n}
          . qq{Try 'git remote add $remote "ssh://user\@example.com/srv/repos/myapp.git"'}
    ) unless $config->remote_url;
    $self->usage_error( qq{Remote $remote deploy dir must be configured.\n}
          . qq{Try 'git config --local remote.$remote.deploy "/srv/apps/myapp"'}
    ) unless $config->deploy_url;

    return $config;
}

sub _run {
    my ($opts) = @_;

    if ( exists $opts->{host} ) {
        remote_run($opts);
    } else {
        local_run($opts);
    }
}

sub _remote_run {
    my ($opts) = @_;

    my $cmd = qq{
        export GIT_DIR="@{[ $config->remote_url->path ]}";
        export GIT_WORK_TREE="@{[ $config->deploy_dir->path ]}";
        cd @{[ $opts->{host}->path ]};
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
    my ($opts) = @_;
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

App::GitDeploy - Command line tool to deploy any application using git

=head1 VERSION

version 1.08

=head1 DESCRIPTION

Deploy apps:

    $ git remote add production "user@example.com:/svr/repos/myapp.git"
    $ git config --local remote.production.deploy /srv/apps/myapp
    $ git deploy setup -r production

Create a `deploy/production/post-receive` with something like:

    function die { echo @$; exit 1; }
    git diff --quiet || die "Changes to production files found.  Aborting."
    git ls-files -o  | grep . >/dev/null && die "Untracked files. Aborting."
    git checkout -f master

Deploy with:

    $ git deploy go

Which will perform the following:

  * Locally run deploy/production/before-deploy
  * git push production master
  * Remotely run deploy/production/post-receive from the /srv/repos/myapp.git
    dir
  * From the /srv/apps/myapp directory, remotely run the following if they exist:
      * deploy/production/before-restart
      * deploy/production/restart
      * deploy/production/after-restart


     dev$ mkdir app 
     dev$ cd app
     dev$ git init . 
    prod$ git init --bare app.git
     dev$ git remote add production ../app.git
     dev$ git push production master


     git release website
     git checkout master
     git merge devel
     git checkout devel
     git push website master
     git tag master

=head1 SEE ALSO

L<https://github.com/git-deploy/git-deploy#WRITING_DEPLOY_HOOKS>
L<https://www.digitalocean.com/community/tutorials/how-to-set-up-automatic-deployment-with-git-with-a-vps>
L<http://gitolite.com/deploy.html>
L<http://krisjordan.com/essays/setting-up-push-to-deploy-with-git>
L<http://www.pythian.com/blog/deploying-stuff-with-git/>
L<https://github.com/mislav/git-deploy>

=head1 BUGS

Please report any bugs or suggestions at 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-GitDeploy>

=head1 THANKS

To...

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
