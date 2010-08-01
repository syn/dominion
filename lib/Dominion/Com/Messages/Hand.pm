package Dominion::Com::Messages::Hand;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'newhand';
has 'cards'    => ( isa => 'Dominion::Set', is => 'rw', required => 1 );

# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		cards => $self->cards,
	};
}
1;
