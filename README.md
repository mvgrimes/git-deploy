

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

  * Locally run deploy/staging/before-deploy
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

