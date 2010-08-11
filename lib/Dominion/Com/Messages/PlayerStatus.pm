package Dominion::Com::Messages::PlayerStatus;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'playerstatus';
has 'action'	 => ( isa => 'Str', is => 'rw', required => 1 );
has 'player'   => ( isa => 'Dominion::Player', is => 'rw', required => 1 );
has 'section'    => ( isa => 'Str', is => 'ro', default => 'game');

# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type      => $self->type,
		action    => $self->action,
		playerid  => $self->player->id,
		name      => $self->player->name,	
		section   => $self->section,	
	};
}
1;
