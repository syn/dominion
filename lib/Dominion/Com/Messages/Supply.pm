package Dominion::Com::Messages::Supply;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'supply';
has 'supply'    => ( isa => 'Dominion::Set', is => 'rw', required => 1 );

# For sending a chat message back to the client

sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		supply => $self->supply,
	};
}
1;
