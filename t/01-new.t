#!perl -T

use Test::More tests => 3;
use Test::Warn;
use CHI;

BEGIN {
    use_ok( 'CHI::Driver::SharedMem' ) || print "Bail out!
";
}

NEW: {
	my $cache = CHI->new(driver => 'SharedMem', shmkey => 1);
	ok(defined($cache));

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
