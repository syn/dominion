package Dominion::Com::Messages::Options::CardChoice;

use Moose;
extends 'Dominion::Com::Messages::Option';

has '+type'      => default => 'cardchoice';
has 'card'       => ( isa => 'Dominion::Card', is => 'rw' , required => 1);
has 'buttons' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Com::Messages::Options::Button]',
    default  => sub { [] },
    handles  => {
        add      => 'push',
        buttons    => 'elements',
        count    => 'count',
        get      => 'get',
    },
);

# For sending a chat message back to the client
sub TO_JSON {
	my ($self) = @_;
	return {
		type => $self->type,
		event => $self->event,
		card => $self->card,
		buttons => [$self->buttons],
	};
}
1;
