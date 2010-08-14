package Dominion::Cards::Feast;

use Moose;
extends 'Dominion::Card';

sub name        { 'Feast' }
sub tags        { qw(kingdom action) }
sub box         { 'Dominion' }
sub cost_coin   { 4 }
sub cost_potion { 0 }

# Trash this card. Gain a card costing up to 5 Gold.
sub action {
    my ($self, $player, $game) = @_;
    my @cards = grep { $_->cost_coin <= 5 } $game->supply->cards;
    $game->trash->add($self);
	$game->interaction_add(Dominion::Interaction::FreeBuy->new(player => $player, cards => [@cards], callback => sub {},message => 'Feast: Gain a card costing up to 5.'));
}

#__PACKAGE__->meta->make_immutable;
1;
