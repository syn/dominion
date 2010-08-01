package Dominion::Com::Messages::EndGame;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'endgame';
has 'results' => ( isa => 'Str', is => 'rw', required => 1 );

has 'results' => (
    traits   => ['Array'],
    default  => sub { [] },
    handles  => {
        add      => 'push',
        results    => 'elements',
    }
);



# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type      => $self->type,
		results   => $self->results,		
	};
}
1;
