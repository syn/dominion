package Dominion::Com::Messages::Options::Discard;

use Moose;
extends 'Dominion::Com::Messages::Option';

has '+type'      => default => 'discard';
has 'numbertodiscard'      => (isa => 'Int' , is => 'rw' , required => 1 , default => 1);
has 'cards' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Card]',
    default  => sub { [] },
    handles  => {
        add      => 'push',
        cards    => 'elements',
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
		cards => [$self->cards],
	};
}
1;
