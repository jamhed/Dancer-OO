package Sample::Base;
use strict;
use parent 'Dancer::OO::Object';
use Dancer::OO::Dancer;

get '' => wrap {
	my ($self, $context, $params) = @_;
	return <<HTML;
<html><body>Holla</body></html>
HTML
};

1;
