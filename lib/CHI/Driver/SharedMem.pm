package CHI::Driver::SharedMem;

# TODO: Locking

use warnings;
use strict;
use Moose;
use IPC::SysV qw(S_IRWXU IPC_CREAT);
use IPC::SharedMem;
use Storable qw(freeze thaw);
use Data::Dumper;
use Digest::MD5;
use Carp;

extends 'CHI::Driver';

has 'size' => (is => 'ro', isa => 'Int', default => 8 * 1024);
has 'shmkey' => (is => 'ro', isa => 'Int');
has 'shm' => (is => 'ro', builder => '_get_shm', lazy => 1);
has '_data_size' => (
	is => 'rw',
	isa => 'Int',
	reader => '_get_data_size',
	writer => '_set_data_size'
);
has '_data' => (
	is => 'rw',
	isa => 'ArrayRef[ArrayRef]',
	reader => '_get_data',
	writer => '_set_data'
);

__PACKAGE__->meta->make_immutable();

=head1 NAME

CHI::Driver::SharedMem - Cache data in shared memory

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

# FIXME - get the pod documentation right so that the layout of the memory
# area looks correct in the man page

=head1 SYNOPSIS

L<CHI> driver which stores data in shared memory objects for persistently over
processes.
Size is an optional parameter containing the size of the shared memory area,
in bytes.
Shmkey is a mandatory parameter containing the IPC key for the shared memory
area. See L<IPC::SharedMem> for more information.

    use CHI;
    my $cache = CHI->new(
    	driver => 'SharedMem',
	size => 8 * 1024,
	shmkey => 12344321,	# Choose something unique
    );
    # ...

The shared memory area is stored thus:

	Number of bytes in the cache [ 4 bytes ]
	'cache' => {
		'namespace1' => {
			'key1' => 'value1',
			'key2' -> 'value2',
			...
		}
		'namespace2' => {
			'key1' => 'value3',
			'key3' => 'value2',
			...
		}
		...
	}

=head1 SUBROUTINES/METHODS

=head2 store

Stores an object in the cache

=cut

sub store {
	my($self, $key, $data) = @_;

	my $h = $self->_data();
	$h->{$self->namespace()}->{$key} = $data;
	$self->_data($h);
}

=head2 fetch

Retrieves an object from the cache

=cut

sub fetch {
	my($self, $key) = @_;

	my $h = $self->_data();
	return $h->{$self->namespace()}->{$key};
}

=head2 remove

Remove an object from the cache

=cut

sub remove {
	my($self, $key) = @_;

	my $h = $self->_data();
	delete $h->{$self->namespace()}->{$key};
	$self->_data($h);
}

=head2 clear

Removes all data from the cache

=cut

sub clear {
	my $self = shift;

	my $h = $self->_data();
	delete $h->{$self->namespace()};
	$self->_data($h);
}

=head2 get_keys

Gets a list of the keys in the cache

=cut

sub get_keys {
	my $self = shift;

	my $h = $self->_data();
	return(keys(%{$h->{$self->namespace()}}));
}

=head2 get_namespaces

Gets a list of the namespaces in the cache

=cut

sub get_namespaces {
	my $self = shift;

	my $h = $self->_data();
	return(keys(%{$h}));
}

sub _get_shm {
	my $self = shift;

	unless($self->shmkey()) {
		carp 'CHI::Driver::SharedMem - no key given';
		return;
	}
	my $shm = IPC::SharedMem->new($self->shmkey(), $self->size(), S_IRWXU);
	unless($shm) {
		$shm = IPC::SharedMem->new($self->shmkey(), $self->size(), S_IRWXU|IPC_CREAT);
		$shm->write(pack('L', 0), 0, 4);
	}
	return $shm;
}

sub _data_size {
	my $self = shift;
	my $value = shift;

	if($value) {
		$self->shm()->write(pack('L', $value), 0, 4);
		return $value;
	}
	unless($self->shm()) {
		return 0;
	}
	return unpack('L', $self->shm()->read(0, 4));
}

sub _data {
	my $self = shift;
	my $h = shift;

	if($h) {
		my $f = freeze($h);
		my $cur_size = length($f);
		$self->shm()->write($f, 4, $cur_size);
		$self->_data_size($cur_size);
		return $h;
	} else {
		my $cur_size = $self->_data_size();
		unless($cur_size) {
			return {};
		}
		return thaw($self->shm()->read(4, $cur_size));
	}
}

=head2 BUILD

Constructor - validate arguments

=cut

sub BUILD {
	my $self = shift;

	unless($self->shmkey()) {
		carp 'CHI::Driver::SharedMem - no key given';
	}
}

=head2 DEMOLISH

If there is no data in the shared memory area, remove it.

=cut

sub DEMOLISH {
	my $self = shift;

	unless($self->_data_size()) {
		if($self->shm()) {
			$self->shm()->remove();
		}
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chi-driver-sharedmem at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CHI-Driver-SharedMem>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

CHI, IPC::SharedMem


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CHI::Driver::SharedMem


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CHI-Driver-SharedMem>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CHI-Driver-SharedMem-Info>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CHI-Driver-SharedMem>

=item * Search CPAN

L<http://search.cpan.org/dist/CHI-Driver-SharedMem>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nigel Horne.

This program is released under the following licence: GPL


=cut

1; # End of CHI::Driver::SharedMem
