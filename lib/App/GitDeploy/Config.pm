package App::GitDeploy::Config;

use 5.012;
use strict;
use warnings;
use Moo;
use URI;
use Git::Wrapper;
use Try::Tiny;

has 'remote'     => ( is => 'ro', required => 1 );
has 'remote_url' => ( is => 'ro', builder  => '_build_remote_url', lazy => 1, );
has 'deploy_url' => ( is => 'ro', builder  => '_build_deploy_url', lazy => 1, );
has 'deploy_dir' => ( is => 'ro', builder  => '_build_deploy_dir', lazy => 1, );

sub _build_deploy_dir {
    my ($self) = @_;

    return $self->_retrieve_url("remote.@{[ $self->remote ]}.deploy");
}

sub _build_deploy_url {
    my ($self) = @_;

    $self->_uri_replace_path( $self->remote_url, $self->deploy_dir->path );
}

sub _build_remote_url {
    my ($self) = @_;

    return $self->_retrieve_url("remote.@{[ $self->remote ]}.url");
}

sub _retrieve_url {
    my ( $self, $key ) = @_;

    my $git = Git::Wrapper->new('.');
    my $value;
    try { ($value) = $git->config( "--local", "--get", $key ); }
    catch { die $_ unless /exited non-zero/ };
    return unless $value;
    return URI->new($value);
}

sub _uri_replace_path {
    my ( $self, $uri, $path ) = @_;
    my $new_uri = $uri->clone;
    $new_uri->path($path);
    return $new_uri;
}

1;
