package Dominion::Com::Messages::Options::Play;

use Moose;
extends 'Dominion::Com::Messages::Option';

has '+type'      => default => 'play';
has 'reveal'     => ( isa => 'Str', is => 'rw', default => "false" );
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
		reveal => $self->reveal,
	};
}
1;
