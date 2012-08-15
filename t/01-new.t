#!perl -T

use Test::More tests => 7;
use Test::Warn;
use CHI;
use IPC::SysV qw(S_IRUSR S_IWUSR);
use IPC::SharedMem;

BEGIN {
    use_ok( 'CHI::Driver::SharedMem' ) || print "Bail out!
";
}

NEW: {
	my $shm = IPC::SharedMem->new(1, 8 * 1024, S_IRUSR|S_IWUSR);
	ok(!defined($shm), 'Shared memory area does not exist before the test');

	{
		my $cache = CHI->new(driver => 'SharedMem', shmkey => 1);
		ok(defined($cache));

		# Calling get_namespaces() will force the area to be created
		my @a = $cache->get_namespaces();
		ok((scalar(@a) == 0), 'The cache is empty');

		$shm = IPC::SharedMem->new(1, 8 * 1024, S_IRUSR|S_IWUSR);
		ok(defined($shm), 'Shared memory exists during the test');

		# diag('Ignore no key given message');
		# warning_like
			# { $cache = CHI->new(driver => 'SharedMem') }
			# { carped => qr/CHI::Driver::SharedMem - no key given/ };

		eval {
			$cache = CHI->new(driver => 'SharedMem');
		};
		if($@) {
			ok($@ =~ /CHI::Driver::SharedMem - no key given/);
		} else {
			ok(0, 'Allowed shmkey to be undefined');
		}
	}

	$shm = IPC::SharedMem->new(1, 8 * 1024, S_IRUSR|S_IWUSR);
	ok(!defined($shm), 'Shared memory area does not exist after the test');
}
