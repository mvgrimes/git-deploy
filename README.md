# NAME

App::GitDeploy - Command line tool to deploy any application using git

# VERSION

version 1.08

# DESCRIPTION

Deploy apps:

    $ git remote add production "user@example.com:/svr/repos/myapp.git"
    $ git config --local remote.production.deploy /srv/apps/myapp
    $ git deploy setup -r production

Create a \`deploy/production/post-receive\` with something like:

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

# SEE ALSO

[https://github.com/git-deploy/git-deploy#WRITING\_DEPLOY\_HOOKS](https://github.com/git-deploy/git-deploy#WRITING_DEPLOY_HOOKS)
[https://www.digitalocean.com/community/tutorials/how-to-set-up-automatic-deployment-with-git-with-a-vps](https://www.digitalocean.com/community/tutorials/how-to-set-up-automatic-deployment-with-git-with-a-vps)
[http://gitolite.com/deploy.html](http://gitolite.com/deploy.html)
[http://krisjordan.com/essays/setting-up-push-to-deploy-with-git](http://krisjordan.com/essays/setting-up-push-to-deploy-with-git)
[http://www.pythian.com/blog/deploying-stuff-with-git/](http://www.pythian.com/blog/deploying-stuff-with-git/)
[https://github.com/mislav/git-deploy](https://github.com/mislav/git-deploy)

# BUGS

Please report any bugs or suggestions at 
[http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-GitDeploy](http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-GitDeploy)

# THANKS

To...

# AUTHOR

Mark Grimes, <mgrimes@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, <mgrimes@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
