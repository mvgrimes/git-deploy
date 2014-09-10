package App::GitDeploy::SSH;

use 5.012;
use strict;
use warnings;
use Moo;
use Net::OpenSSH;
use Expect;
use Term::ReadKey;

# use namespace::sweep;

has 'ssh' => ( is => 'ro', builder => '_ssh_builder', lazy => 1, );
has 'uri' => ( is => 'ro', required => 1, );

sub _ssh_builder {
    my ($self) = @_;

    # use Data::Printer;
    # p $self->uri;
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
    my $ssh = $self->ssh;
    my ( $pty, $pid ) =
      $ssh->open2pty( { stderr_to_stdout => 1, tty => 1 }, $cmd )
      or die "Error executing on remote: " . $ssh->error;

    my $expect = Expect->init($pty);
    $expect->log_stdout(1);
    $expect->expect(
        240,
        [
            qr/\[sudo\] password for (.*): / => sub {
                my $exp      = shift;
                my $password = get_pw();
                $exp->send("$password\n");
                print "sent\n";
                exp_continue;
              }
        ],
    );
}

sub get_pw {
    my $prompt = shift;

    $|++;
    print $prompt if defined $prompt;

    ReadMode('noecho');
    ReadMode('raw');

    my $pass = '';
    while (1) {
        my $c;
        1 until defined( $c = ReadKey(-1) );
        exit if ord($c) == 3;    # ctrl-c
        last if $c eq "\n";
        print "*";
        $pass .= $c;
    }
    print "\n";

    END { ReadMode('restore'); }

    return $pass;
}

sub test {
    my ( $self, $cmd ) = @_;

    say "SSH testing [$cmd]";
    return $self->ssh->test($cmd);
}

1;

__END__

=pod

=head1 NAME

App::GitDeploy::SSH

=head1 VERSION

version 1.03

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
