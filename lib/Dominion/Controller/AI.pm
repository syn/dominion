package Dominion::Controller::AI;

use 5.010;
use Moose;

extends 'Dominion::Controller';

sub init  {
	my ($self) = @_;
	$self->SUPER::init();
	$self->player->isbot(1);
}

#__PACKAGE__->meta->make_immutable;
1;
