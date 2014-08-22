

    $ git remote add production "user@example.com:/svr/repos/myapp.git"
    $ git config --local remote.production.deploy /srv/apps/myapp
    $ git deploy setup
    $ git deploy go


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

