package Dominion::Com::Messages::Options::Button;

use Moose;
extends 'Dominion::Com::Messages::Option';

has '+type'      => default => 'button';
has 'name'      => ( isa => 'Str', is => 'rw', required => 1 );
has 'param'      => ( isa => 'Str', is => 'rw', default => '' );

# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		event => $self->event,
		name => $self->name,
		param => $self->param,
	};
}
1;
