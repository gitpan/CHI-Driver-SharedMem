use strict;
use warnings;
use ExtUtils::MakeMaker;

if($^O eq 'MSWin32') {
	# This will set fail. I really want the result to be NA, but I can't
	# find how to do that.
	die 'Windows is not supported';
}

WriteMakefile(
    NAME                => 'CHI::Driver::SharedMem',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CHI/Driver/SharedMem.pm',
    ABSTRACT_FROM       => 'lib/CHI/Driver/SharedMem.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.82,	# Needs new_ok
	'Test::NoWarnings' => 0,
	'Test::Warn' => 0,
	'Test::Class' => 0,
	'Storable' => 0,
	'Moose' => 0,
	'IPC::SysV' => 0,
	'IPC::SharedMem' => 0,
	'CHI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CHI-Driver-SharedMem-*' },
);
