package Dominion::Com::Messages::Ping;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'ping';
has 'section'    => ( isa => 'Str', is => 'ro', default => 'lobby');

# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type      => $self->type,	
		section   => $self->section,	
	};
}
1;
