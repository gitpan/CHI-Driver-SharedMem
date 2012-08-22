package CHI::Driver::SharedMem::t::CHIDriverTests;

use strict;
use warnings;
use CHI::Test;
use base qw(CHI::t::Driver);
use Test::Warn;
use IPC::SysV;

=head1 NAME

CHI::Driver::SharedMem::t::CHIDriverTests

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

CHI::Driver::SharedMem::t::CHIDriverTests - test CHI::Driver::SharedMem

=cut

=head1 SUBROUTINES/METHODS

=head2 testing_driver_class

Declare the driver being tested

=cut

sub testing_driver_class {
	'CHI::Driver::SharedMem'
}

=head2 new_cache_options

=cut
sub new_cache_options {
	my $self = shift;

	return (
	    $self->SUPER::new_cache_options(),
	    driver => '+CHI::Driver::SharedMem',
	    size => 16 * 1024,
	    shmkey => IPC::SysV::ftok($0),	# hope it's unique :-(
	);
}

=head2 test_shmkey_required

Verify that the shmkey option is mandatory

=cut

sub test_shmkey_required : Tests {
	my $cache;

	eval {
		$cache = CHI->new(driver => 'SharedMem');
	};
	if($@) {
		ok($@ =~ /CHI::Driver::SharedMem - no key given/);
		ok(!defined($cache));
	} else {
		ok(0, 'Allowed shmkey to be undefined');
	}
}

1;
