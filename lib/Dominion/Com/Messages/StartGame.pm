package Dominion::Com::Messages::StartGame;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'startgame';

# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type      => $self->type,		
	};
}
1;
