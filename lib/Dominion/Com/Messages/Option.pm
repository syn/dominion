package Dominion::Com::Messages::Option;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'newhand';
has 'event'      => ( isa => 'Str', is => 'rw', required => 1 );  #The event that gets sent back if the client selects this option
has 'section'    => ( isa => 'Str', is => 'ro', default => 'game');

# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		cards => $self->cards,
		section   => $self->section,
	};
}
1;
