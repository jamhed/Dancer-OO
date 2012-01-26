package Dancer::OO::Dancer;
use strict;
use Dancer ();
use YAML;

our @route_handler = qw( get post any patch del options put );

sub debug {
	Dancer::debug( join( ' ', map { ref $_ ? Dump($_) : $_ } map { $_ ? $_ : '_' } @_ ) );
}

sub import {
	my ($self) = @_;
	my $class = caller;
	no strict 'refs';

	# redefine router handlers
	foreach my $handler (@route_handler) {
		*{"$class\::$handler"} = sub {
			push @{ ${"$class\::_handler"} }, [ $handler, @_ ];
		};
	}

	# dancer improvements
	*{"$class\::template"} = sub {
		my ( $self, $template, $args ) = @_;
		$args = {} unless $args;
		$args->{uri} = sub { join( '', ${"$self\::_prefix"}, $_[0] ) };
		my $k = join( '/', ${"$self\::_prefix"}, 'pager' );
		$args->{c} ||= Dancer::session($k) || {};
		return Dancer::template( join( '/', ${"$self\::_prefix"}, $template ), $args );
	};

	*{"$class\::wrap"}         = sub (&) {
		my ($handler) = @_;
		return sub {
			my ($self) = @_;
			return sub {
				my $params	= Dancer::params;
				my $context	= Dancer::session;
				my $ret     = $handler->( $self, $context, $params );
				Dancer::session( $context );
				return $ret;
			  }
		  }
	};

	*{"$class\::debug"} = \&debug;

	# suck in all Dancer methods
	for my $method (@Dancer::EXPORT) {
		*{"$class\::$method"} = *{"Dancer\::$method"} if not defined &{"$class\::$method"};
	}
}

1;
