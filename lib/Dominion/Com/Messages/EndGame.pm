package Dominion::Com::Messages::EndGame;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'endgame';
has 'results' => (
    traits   => ['Array'],
    default  => sub { [] },
    handles  => {
        add      => 'push',
        results    => 'elements',
    }
);
has 'section'    => ( isa => 'Str', is => 'ro', default => 'game');



# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type      => $self->type,
		results   => [$self->results],	
		section   => $self->section,	
	};
}
1;
