package CHI::Driver::SharedMem;

# FIXME: no locking is done yet

# Fails tests:
#   Failed test 'cache isa CHI::Driver::CHIDriverTests'
#   at /usr/local/share/perl/5.14.2/CHI/t/Driver.pm line 857.
#   (in CHI::Driver::SharedMem::t::CHIDriverTests->test_l1_cache)
#     cache isn't a 'CHI::Driver::CHIDriverTests' it's a 'Moose::Meta::Class::__ANON__::SERIAL::3'
# etc.
# I don't know why

use warnings;
use strict;
use Moose;
use IPC::SysV qw(S_IRWXU IPC_CREAT);
use IPC::SharedMem;
use Storable qw(freeze thaw);
use Data::Dumper;
use Digest::MD5;

extends 'CHI::Driver';

has 'size' => (is => 'ro', isa => 'Int', default => 8 * 1024);
has 'shmkey' => (is => 'ro', isa => 'Int', default => 0);
has 'shm' => (is => 'ro', builder => '_get_shm', lazy => 1);

__PACKAGE__->meta->make_immutable();

=head1 NAME

CHI::Driver::SharedMem - Cache data in shared memory

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

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

	# warn "store $key";
	my $h;
	my $cur_size = unpack('L', $self->shm()->read(0, 4));
	# warn "store - old cur_size $cur_size";
	if($cur_size) {
		$h = thaw($self->shm()->read(4, $cur_size));
	}
	$h->{$self->namespace()}->{$key} = $data;
	my $f = freeze($h);
	$cur_size = length($f);
	$self->shm()->write(pack('L', $cur_size), 0, 4);
	$self->shm()->write($f, 4, $cur_size);
	# warn "store - new cur_size $cur_size";
	# warn Dumper($h);
}

=head2 fetch

Retrieves an object from the cache

=cut

sub fetch {
	my($self, $key) = @_;

	my $cur_size = unpack('L', $self->shm()->read(0, 4));
	# warn "fetch - cur_size " . $cur_size;
	unless($cur_size) {
		return;
	}
	my $f = $self->shm()->read(4, $cur_size);
	my $h = thaw($f);
	# warn Dumper($h);
	return $h->{$self->namespace()}->{$key};
}

=head2 remove

Remove an object from the cache

=cut

sub remove {
	my($self, $key) = @_;

	# warn "remove $key";
	# warn "remove - cur_size " . $self->cur_size();
	my $cur_size = unpack('L', $self->shm()->read(0, 4));
	unless($cur_size) {
		return;
	}
	my $h = thaw($self->shm()->read(4, $cur_size));

	delete $h->{$self->namespace()}->{$key};

	my $f = freeze($h);
	$cur_size = length($f);
	$self->shm()->write(pack('L', $cur_size), 0, 4);
	$self->shm()->write($f, 4, $cur_size);
	# warn Dumper($h);
	# warn "remove - cur_size " . $self->cur_size();
}

=head2 clear

Removes all data from the cache

=cut

sub clear {
	my $self = shift;

	# warn "clear";
	my $cur_size = unpack('L', $self->shm()->read(0, 4));
	unless($cur_size) {
		return;
	}
	my $h = thaw($self->shm()->read(4, $cur_size));

	delete $h->{$self->namespace()};

	my $f = freeze($h);
	$cur_size = length($f);
	$self->shm()->write(pack('L', $cur_size), 0, 4);
	$self->shm()->write($f, 4, $cur_size);
}

=head2 get_keys

Gets a list of the keys in the cache

=cut

sub get_keys {
	my $self = shift;

	# warn "get_keys";
	if(!defined($self->shm())) {
		return keys({});
	}
	my $cur_size = unpack('L', $self->shm()->read(0, 4));
	unless($cur_size) {
		# warn "get_keys where's me keys?";
		return keys({});
	}
	my $h = thaw($self->shm()->read(4, $cur_size));

	return(keys(%{$h->{$self->namespace()}}));
}

=head2 get_namespaces

Gets a list of the namespaces in the cache

=cut

sub get_namespaces {
	my $self = shift;

	# warn "get_namespaces";
	if(!defined($self->shm())) {
		return keys({});
	}
	my $cur_size = unpack('L', $self->shm()->read(0, 4));
	unless($cur_size) {
		# warn "get_keys where's me keys?";
		return keys({});
	}
	my $h = thaw($self->shm()->read(4, $cur_size));

	return(keys(%{$h}));
}

sub _get_shm {
	my $self = shift;

	# warn "_get_shm";

	unless($self->shmkey()) {
		warn 'CHI::Driver::SharedMem - no key given';
		return;
	}

	my $shm = IPC::SharedMem->new($self->shmkey(), $self->size(), S_IRWXU);
	unless($shm) {
		$shm = IPC::SharedMem->new($self->shmkey(), $self->size(), S_IRWXU|IPC_CREAT);
		$shm->write(pack('L', 0), 0, 4);
	}
	return $shm;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chi-driver-sharedmem at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CHI-Driver-SharedMem>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

CHI, IPC::SharedMem;


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
