package App::GitDeploy::Command::setup;

use strict;
use warnings;
use Path::Class;

use App::GitDeploy -command;

our $VERSION = '1.00';

sub opt_spec {
    # return ( [ "filename|f=s", "The filename and path of the package", ] );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    return 1;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;
    return;
}

1;
