package Dominion::Com::Messages::Choice;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'choice';
has 'message'    => ( isa => 'Str', is => 'rw', required => 1 );
has 'modal'      => ( isa => 'Str', is => 'rw', default => 'false');
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
has 'section'    => ( isa => 'Str', is => 'ro', default => 'game');
# For sending a chat message back to the client

sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		message =>  $self->message,
		choice => [$self->options],
		section   => $self->section,
		modal => $self->modal,
	};
}
1;
