package Dominion::Controller::AI;

use Moose;
use Moose::Util::TypeConstraints;
use Dominion::Interactions;
use Data::Dumper;
no warnings 'recursion';

extends 'Dominion::Controller';

sub interaction {
	my ( $self, @data ) = @_;
	my $state       = $data[1];
	my $interaction = $data[2];
	print "Handling interaction " . $interaction->cause . "\n";

	#Look through the interaction option list
	foreach my $option ( $interaction->options )
	{
		match_on_type $option => (
			'Dominion::Interactions::Discard'  => sub { 
				my $o = $self->discard($option);
				$interaction->resolveCallback->($interaction,$o);
				return;
			},
		),
	}
}

sub discard {
	my($self,$option) = @_;
	my @arr = $option->cards;
	my @bob = splice(@arr, 0, $option->numbertodiscard);
	$option->discard_add(@bob);
	return $option; 		
}
1;
