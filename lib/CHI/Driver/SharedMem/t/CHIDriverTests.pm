package CHI::Driver::SharedMem::t::CHIDriverTests;
# package CHI::t::Driver::SharedMem;

use strict;
use warnings;
use CHI::Test;
use base qw(CHI::t::Driver);
use Test::Warn;

=head1 NAME

CHI::Driver::SharedMem::t::CHIDriverTests

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

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
	    shmkey => 12344321,	# hope it's unique :-(
	);
}

=head2 test_shmkey_required

The shmkey option is mandatory

=cut

sub test_shmkey_required : Tests {
	my $cache;

	diag('Ignore no key given message');
	warning_like(sub { $cache = CHI->new(driver => 'SharedMem') },
		qr /CHI::Driver::SharedMem - no key given/
	);
	# ok(!$cache);
}

1;
