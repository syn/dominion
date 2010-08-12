package Dominion::Com::Messages::ListofGames;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'listofgames';
has 'section'    => (isa => 'Str', is => 'ro', default => 'lobby');
has 'games' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Game]',
    default  => sub { [] },
    handles  => {
        games         => 'elements',
        games_add      => 'push',
        games_count    => 'count',
        games_number   => 'get',
        games_clear    => 'clear',
        games_delete   => 'delete',
    },
);
# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	print "In ListOfGames json\n";
	return {
		type      => $self->type,
		games   => [$self->games],	
		section   => $self->section,	
	};
}
1;
