package App::GitDeploy::Command::go;

use 5.012;
use strict;
use warnings;
use Path::Class;
use IPC::Cmd;
use Git::Wrapper;
use Data::Printer;
use URI;
use autodie;
use Path::Class qw(dir file);
use File::chdir;
use Net::OpenSSH;
use App::GitDeploy::SSH;

use App::GitDeploy -command;

our $VERSION = '1.00';

sub opt_spec {
    return (
        [ "app|a=s",    "The app to deploy", { default => '.' } ],
        [ "remote|r=s", "The remote repos",  { default => 'production' } ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    my $app          = $opt->{app};
    my $post_receive = "deploy/$app/production/post-receive";

    $self->usage_error("A valid app must be specificed")
      unless -d "deploy/$app/";
    $self->usage_error("$post_receive must be created")
      unless -e $post_receive;
    $self->usage_error("$post_receive must be executable")
      unless -x $post_receive;

    my $remote     = $opt->{remote};
    my $remote_url = remote_url($remote);
    $self->usage_error(
        qq{Remote $remote must be configured. Try 'git remote add production "user\@example.com:/srv/apps/myapp"'}
    ) unless $remote_url;

    $opt->{remote_url} = $remote_url;

    return 1;
}

sub remote_url {
    my ($remote) = @_;

    my $git = Git::Wrapper->new('.');
    my ($url) = $git->config( '--local', '--get', "remote.$remote.url" );
    return unless $url;
    return URI->new($url);
}

sub execute {
    my ( $self, $opt, $arg ) = @_;
    my $app = $opt->{app};

    run( { cmd => "deploy/$app/staging/before-deploy", if_exists => 1 } );
    run( { cmd => "git push production master" } );
    run( { cmd => "deploy/$app/staging/after-deploy",  if_exists => 1 } );

    my $post_receive =
      file("deploy/$app/production/post-receive")->cleanup->stringify;
    run( {
        cmd  => qq{eval "\$( git show master:$post_receive )"},
        host => $opt->{remote_url},
    } );

    run( {
        cmd  => "deploy/$app/production/before-restart",
        host => uri_replace_path( $opt->{remote_url}, git_work_tree() ),
        if_exists => 1
    } );
    run( {
        cmd  => "deploy/$app/production/restart",
        host => uri_replace_path( $opt->{remote_url}, git_work_tree() ),
        if_exists => 1
    } );
    run( {
        cmd  => "deploy/$app/production/after-restart",
        host => uri_replace_path( $opt->{remote_url}, git_work_tree() ),
        if_exists => 1
    } );
}

sub uri_replace_path {
    my ( $uri, $path ) = @_;
    my $new_uri = $uri->clone;
    $new_uri->path($path);
    return $new_uri;
}

sub git_dir {
    my $git = Git::Wrapper->new('.');
    return URI->new( $git->config(qw( --local --get remote.production.url )) );
}

sub git_work_tree {
    my $git = Git::Wrapper->new('.');
    return URI->new(
        $git->config(qw( --local --get remote.production.deploy )) );
}

sub run {
    my ($opts) = @_;

    if ( exists $opts->{host} ) {
        remote_run($opts);
    } else {
        local_run($opts);
    }
}

sub remote_run {
    my ($opts) = @_;

    my $cmd = qq{
        export GIT_DIR="@{[ git_dir->path ]}";
        export GIT_WORK_TREE="@{[ git_work_tree->path ]}";
        cd @{[ $opts->{host}->path ]};
        $opts->{cmd} };

    if ( $opts->{host}->scheme eq 'ssh' ) {
        my $ssh = App::GitDeploy::SSH->new( uri => $opts->{host} );

        if ( $opts->{if_exists} ) {
            my $test_cmd = qq{
                cd @{[ $opts->{host}->path ]};
                test -x $opts->{cmd} };
            return unless $ssh->test($test_cmd);
        }

        $ssh->run($cmd);
    } else {
        local $CWD = $opts->{host}->path;

        die "Remote path doesn't appear to exist"
          unless -d $opts->{host}->path;

        local_run( { $opts, cmd => $cmd } );
    }

}

sub local_run {
    my ($opts) = @_;
    my $buffer;

    if ( $opts->{if_exists} ) {
        my ( $cmd, undef ) = split / /, $opts->{cmd}, 2;
        return unless IPC::Cmd::can_run($cmd);
    }

    IPC::Cmd::run(
        command => $opts->{cmd},
        verbose => 1,
        buffer  => \$buffer,
    ) or die "Error running '$opts->{cmd}'\n";
}

1;
