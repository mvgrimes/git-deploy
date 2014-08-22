package App::GitDeploy;

# ABSTRACT: Command line tool to deploy any application using git

use strict;
use warnings;

use App::Cmd::Setup -app;

our $VERSION = '1.00';

1;

__END__

=pod

=head1 NAME

App::EditorTools - Command line tool for Perl code refactoring

=head1 VERSION

version 1.00

=head1 DESCRIPTION

C<App::EditorTools> provides the C<editortools> command line program that
enables programming editors (Vim, Emacs, etc.) to take advantage of some
sophisticated Perl refactoring tools. The tools utilize L<PPI> to analyze
Perl code and make intelligent changes. As of this release, C<editortools> 
is able to:

=head1 SEE ALSO

L<https://github.com/git-deploy/git-deploy#WRITING_DEPLOY_HOOKS>
L<https://www.digitalocean.com/community/tutorials/how-to-set-up-automatic-deployment-with-git-with-a-vps>
L<http://gitolite.com/deploy.html>
L<http://krisjordan.com/essays/setting-up-push-to-deploy-with-git>
L<http://www.pythian.com/blog/deploying-stuff-with-git/>
L<https://github.com/mislav/git-deploy>

=head1 BUGS

Please report any bugs or suggestions at 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-GitDeploy>

=head1 THANKS

To...

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
