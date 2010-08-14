package Dominion::Interaction::FreeBuy;

use Moose;

extends 'Dominion::Interaction';

has 'cancelled' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'cards' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Card]',
    default  => sub { [] },
    handles  => {
        add      => 'push',
        cards    => 'elements',
    }
);

sub play {
    my ($self, $card_name) = @_;

    my $card = $self->player->game->supply->card_by_name($card_name);
	$self->player->discard->add($card);
	$self->player->emit('broughtcard',$card);
}

sub cancel {
    my ($self) = @_;
	$self->resolved(1);
    $self->cancelled(1);
}

sub done {
    my ($self) = @_;

    $self->callback->() if $self->callback and not $self->cancelled;
    $self->resolved(1);
}

#__PACKAGE__->meta->make_immutable;
1;
