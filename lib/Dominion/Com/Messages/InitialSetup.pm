package Dominion::Com::Messages::InitialSetup;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'InitialSetup';
has 'name'	 => ( isa => 'Str', is => 'rw', required => 1 );
has 'gamestatus'   => ( isa => 'Str', is => 'rw', required => 1 );

# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type      => $self->type,
		gamestatus    => $self->gamestatus,
		name      => $self->name,		
	};
}
1;
