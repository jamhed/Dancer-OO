package Dancer::OO::Dancer;
use strict;
use Dancer ();
use JSON;

sub debug {
	Dancer::debug( join( ' ', map { ref $_ ? Dump($_) : $_ } map { $_ ? $_ : '_' } @_ ) );
}

sub import {
	my ($self) = @_;
	my $class = caller;
	no strict 'refs';
	*{"$class\::get"} = sub {
		push @{ ${"$class\::_handler"} }, [ 'get', @_ ];
	};
	*{"$class\::post"} = sub {
		push @{ ${"$class\::_handler"} }, [ 'post', @_ ];
	};
	*{"$class\::any"} = sub {
		push @{ ${"$class\::_handler"} }, [ 'any', @_ ];
	};
	*{"$class\::template"} = sub {
		my ( $self, $template, $args ) = @_;
		$args = {} unless $args;
		$args->{uri} = sub { join( '', ${"$self\::_prefix"}, $_[0] ) };
		my $k = join( '/', ${"$self\::_prefix"}, 'pager' );
		$args->{c} ||= Dancer::session($k) || {};
		return Dancer::template( join( '/', ${"$self\::_prefix"}, $template ), $args );
	};
	*{"$class\::upload"}       = \&Dancer::upload;
	*{"$class\::content_type"} = \&Dancer::content_type;
	*{"$class\::header"}       = \&Dancer::header;
	*{"$class\::redirect"}     = \&Dancer::redirect;
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

	*{"$class\::json"} = sub { JSON->new->utf8(0)->pretty(1)->encode(shift) };
	*{"$class\::debug"} = \&debug;

	*{"$class\::params"} = \&Dancer::params;
	*{"$class\::session"} = \&Dancer::session;
}

1;
