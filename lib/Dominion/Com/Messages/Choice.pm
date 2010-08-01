package Dominion::Com::Messages::Choice;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'choice';
has 'message'    => ( isa => 'Str', is => 'rw', required => 1 );
has 'options' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Com::Messages::Option]',
    default  => sub { [] },
    handles  => {
        add      => 'push',
        options    => 'elements',
        count    => 'count',
        get      => 'get',
    },
);
# For sending a chat message back to the client

sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		message =>  $self->message,
		choice => [$self->options],
	};
}
1;
