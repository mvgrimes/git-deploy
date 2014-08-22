package App::GitDeploy::SSH;

use 5.012;
use strict;
use warnings;
use Moo;
use Net::OpenSSH;

# use namespace::sweep;

has 'ssh' => ( is => 'ro', builder => '_ssh_builder', lazy => 1, );
has 'uri' => ( is => 'ro', required => 1, );

sub _ssh_builder {
    my ($self) = @_;

    my $ssh = Net::OpenSSH->new(
        $self->uri->host,
        user     => $self->uri->user,
        port     => $self->uri->port,
        password => $self->uri->password,
    );
    $ssh->error and die "Can't ssh to host: " . $ssh->error;

    # $ssh->test( 'cd', $self->uri->path )
    #   or die "unable to cd into the remote dir: "
    #   . $self->uri->path . "\n"
    #   . $ssh->error;

    return $ssh;
}

sub run {
    my ( $self, $cmd ) = @_;

    say "SSH running [$cmd]";
    $self->ssh->system($cmd)
      or die "Error executing on remote: " . $self->ssh->error;
}

sub test {
    my ( $self, $cmd ) = @_;

    say "SSH testing [$cmd]";
    return $self->ssh->test($cmd);
}

1;
