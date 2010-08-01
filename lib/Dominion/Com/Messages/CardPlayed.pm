package Dominion::Com::Messages::CardPlayed;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'cardplayed';
has 'actiontype' => ( isa => 'Str', is => 'rw', required => 1 );
has 'player'     => ( isa => 'Dominion::Player', is => 'rw', required => 1 );
has 'card'       => ( isa => 'Dominion::Card', is => 'rw' , required => 1);


# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type      => $self->type,
		actiontype=> $self->actiontype,
		playerid  => $self->player->id,
		name      => $self->player->name,
		card      => $self->card,		
	};
}
1;
