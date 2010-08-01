package Dominion::Com::Messages::Options::Buy;

use Moose;
extends 'Dominion::Com::Messages::Option';

has '+type'      => default => 'buy';
has 'cards' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Card]',
    default  => sub { [] },
    handles  => {
        add      => 'push',
        cards    => 'elements',
    }
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
