package Dominion::Com::Messages::Options::Trash;

use Moose;
extends 'Dominion::Com::Messages::Option';

has '+type'      => default => 'discard';
has 'cards'      => ( isa => 'Dominion::Set', is => 'rw', required => 1 );
# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		event => $self->event,
		cards => $self->cards,
	};
}
1;
