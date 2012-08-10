package CHI::Driver::SharedMem::t::CHIDriverTests;
use strict;
use warnings;
use CHI::Test;
use base qw(CHI::t::Driver);

=head1 NAME

CHI::Driver::SharedMem::t::CHIDriverTests

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

CHI::Driver::SharedMem::t::CHIDriverTests - test CHI::Driver::SharedMem

=cut

=head1 SUBROUTINES/METHODS

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

1;
