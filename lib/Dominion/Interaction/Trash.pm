package Dominion::Interaction::Trash;

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

has 'count' => ( is => 'rw', isa => 'Int', default => 0 );

sub play {
    my ($self, $card_name) = @_;
    my $card = $self->player->hand->card_by_name($card_name);
	$self->player->game->trash->add($card);
	$self->player->emit('trashcard',$card);
	$self->count--;
	$self->done if $self->count == 0;
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
