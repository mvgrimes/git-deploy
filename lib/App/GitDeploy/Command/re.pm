package App::GitDeploy::Command::re;

use 5.012;
use strict;
use warnings;
use Moo;

extends 'App::GitDeploy::Command::go';

around 'execute' => sub {
    my ( $orig, $self, $opt, $arg ) = ( shift, shift, shift, shift );
    $opt->{skip} = 1;
    $self->$orig( $opt, $arg, @_ );
};

1;

