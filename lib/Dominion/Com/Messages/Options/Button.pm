package Dominion::Com::Messages::Options::Button;

use Moose;
extends 'Dominion::Com::Messages::Option';

has '+type'      => default => 'button';
has 'name'      => ( isa => 'Str', is => 'rw', required => 1 );

# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		event => $self->event,
		name => $self->name,
	};
}
1;
