requires 'perl'                => '5.012';
requires 'App::Cmd'            => 0;
requires 'IPC::System::Simple' => 0;
requires 'Path::Tiny'          => 0;
requires 'Git::Wrapper'        => 0;
requires 'Data::Printer'       => 0;
requires 'autodie'             => 0;
requires 'URI'                 => 0;
requires 'File::chdir'         => 0;
requires 'Net::OpenSSH'        => 0;
requires 'IO::Pty'             => 0;
requires 'IO::Stty'            => 0;
requires 'IO::Prompter'        => 0;
requires 'Expect'              => 0;
requires 'Moo'                 => 0;
requires 'File::ShareDir'      => 0;
requires 'Term::ReadKey'       => 0;
requires 'Term::ANSIColor'     => 0;
requires 'Perl6::Junction'     => 0;

on 'test' => sub {
    requires 'Test::Differences' => 0;
    requires 'Test::More'        => 0.87;
};
