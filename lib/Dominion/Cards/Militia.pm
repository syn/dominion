package Dominion::Cards::Militia;

use Moose;
extends 'Dominion::Card';

sub name        { 'Militia' }
sub tags        { qw(kingdom action) }
sub box         { 'Dominion' }
sub cost_coin   { 4 }
sub cost_potion { 0 }

# Attack
# +2 Gold
# Each other player discards down to 3 cards in his hand.

sub action {
    my ($self, $player) = @_;

    # +1 coin
    $player->coin_add(2);
    
    #Send an interaction to make the other players respond to the attack
    foreach my $otherplayer ( $player->game->players ) {
		if($otherplayer ne $player) {	
			
		}
	}
    
    
}

#__PACKAGE__->meta->make_immutable;
1;
