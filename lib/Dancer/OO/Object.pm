package Dancer::OO::Object;
use strict;
use Dancer::OO::Dancer qw( debug );

# this module actually installs deferred and properly stacked uri handlers

sub _build_tree {
	my ($package) = @_;
	return unless $package;
	no strict 'refs';
	return map { $_, _build_tree($_) } @{"$package\::ISA"};
}

# delay declarations
sub import {
	my ( $self, $prefix ) = @_;
	no strict 'refs';
	${"$self\::_prefix"} = $prefix;
	my @tree = ($self, _build_tree($self));
	my %seen;
	foreach my $isa (@tree) {
		foreach ( @{ ${"$isa\::_handler"} } ) {
			my $path = join( '', $_->[0], $prefix, $_->[1] ) || '/';
			next if $seen{$path};
			debug( 'for', $self, $_->[0], $prefix . $_->[1], 'in', $isa);
			$seen{$path} = 1;
			Dancer::get $prefix . $_->[1]  => $_->[2]->($self) if $_->[0] eq 'get';
			Dancer::post $prefix . $_->[1] => $_->[2]->($self) if $_->[0] eq 'post';
			Dancer::any $prefix . $_->[1]  => $_->[2]->($self) if $_->[0] eq 'any';
		}
	}
}

1;
