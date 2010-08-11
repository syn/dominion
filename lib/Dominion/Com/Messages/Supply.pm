package Dominion::Com::Messages::Supply;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'supply';
has 'supply'    => ( isa => 'Dominion::Set', is => 'rw', required => 1 );
has 'section'    => ( isa => 'Str', is => 'ro', default => 'game');

# For sending a chat message back to the client

sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		supply => $self->supply,
		section   => $self->section,
	};
}
1;
