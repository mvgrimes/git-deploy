package App::GitDeploy;

# ABSTRACT: Command line tool to deploy any application using git

use 5.012;
use strict;
use warnings;
use App::GitDeploy::Config;

use App::Cmd::Setup -app;

our $VERSION = '1.14';

sub global_opt_spec {
    return (
        [ "app|a=s",      "The app to deploy", { default => '.' } ],
        [ "remotes|r=s@", "The remote repos",  { default => 'production' } ],
        [ "dry-run|n!",   "Don't do it",       { default => '0' } ],
    );
}

sub validate_global_opts {
    my ($self) = @_;

    $self->_chdir_root;
    $self->usage_error("Not able to chdir to root of repo") unless -e '.git';

    my $remotes = $self->global_options->{remotes};
    $remotes = $self->global_options->{remotes} = [$remotes]
      unless ref $remotes;

    for my $remote (@$remotes) {
        $self->usage_error( qq{Remote $remote must be configured.\n}
              . qq{Try 'git remote add $remote "ssh://user\@example.com/srv/repos/myapp.git"'}
        ) unless $self->config->{$remote}->remote_url;

        $self->usage_error( qq{Remote $remote deploy dir must be configured.\n}
              . qq{Try 'git config --local remote.$remote.deploy "/srv/apps/myapp"'}
        ) unless $self->config->{$remote}->deploy_url;
    }

    return $self->config;
}

sub config {
    my ($self) = @_;
    state $config;

    my $remotes = $self->global_options->{remotes};
    for my $remote (@$remotes) {
        $config->{$remote} ||= App::GitDeploy::Config->new( remote => $remote );
    }

    return $config;
}

sub _chdir_root {
    my ($self) = @_;

    my $root_dir = `git rev-parse --show-toplevel`;
    chomp $root_dir;

    $self->usage_error("Are we in a git repo?") unless $root_dir;

    chdir $root_dir;
}

sub default_command { 'go' }

1;

__END__

=pod

=head1 NAME

App::GitDeploy - Command line tool to deploy any application using git

=head1 VERSION

version 1.14

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

=head1 THANKS

To...

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
