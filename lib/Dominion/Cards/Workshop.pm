package Dominion::Cards::Workshop;

use Moose;
use Dominion::Interaction::FreeBuy;
extends 'Dominion::Card';


sub name        { 'Workshop' }
sub tags        { qw(kingdom action) }
sub box         { 'Dominion' }
sub cost_coin   { 3 }
sub cost_potion { 0 }

# Gain a card costing up to 4

sub action {
    my ($self, $player, $game) = @_;
    my @cards = grep { $_->cost_coin <= 4 } $game->supply->cards;
	$game->interaction_add(Dominion::Interaction::FreeBuy->new(player => $player, cards => [@cards], callback => sub {},message => 'Workshop: Gain a card costing up to 4.'));
}

#__PACKAGE__->meta->make_immutable;
1;
