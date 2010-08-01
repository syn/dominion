package Dominion::Com::Messages::Chat;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'message';
has 'message'    => ( isa => 'Str', is => 'rw', required => 1 );
has 'from'		 => ( isa => 'Str', is => 'rw', required => 1 );


# For sending a chat message back to the client

sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		message =>  $self->message,
		from => $self->from,
	};
}
1;
