package Dominion::Cards::Militia;

use Moose;
use Dominion::InteractionOptions;
use Dominion::Interactions;
use Data::Dumper;

extends 'Dominion::Card';

sub name        { 'Militia' }
sub tags        { qw(kingdom action attack) }
sub box         { 'Dominion' }
sub cost_coin   { 4 }
sub cost_potion { 0 }

# Attack
# +2 Gold
# Each other player discards down to 3 cards in his hand.

sub action {
    my ($self, $player) = @_;
	
	print "Resolving Militia\n";
    # +2 coin
    $player->coin_add(2);
    
    $player->turnstate('waitingoninteraction');
    #Send an interaction to make the other players respond to the attack
    foreach my $otherplayer ( $player->game->players ) {
		if($otherplayer ne $player) {	
			
			my $option = Dominion::Interactions::Discard->new(numbertodiscard => $otherplayer->hand->count-3);
			for (my $i = 0; $i < $otherplayer->hand->count ; $i++) {
				$option->add($otherplayer->hand->get($i));
			}
			my $interaction = Dominion::InteractionOptions->new(cause => 'Militia' , player => $otherplayer,card => $self);
			$interaction->add($option);
			$interaction->resolveCallback(\&resolve);
			$player->game->interaction_add($interaction);
			
		}
	}   
}

sub resolve {
	#This is where we check the militia has been resolved to our satisfaction and if necsassry do further interaction
	my ($interaction,$option) = @_;
	foreach my $card ($option->discards) {
		print "discarding " . $card->name . "\n";
		$interaction->player->discard->add($card);
		$interaction->player->emit('responsecard',('Militiaresolve',$card));
	}
	$interaction->player->game->interaction_remove($interaction);
	
}
#__PACKAGE__->meta->make_immutable;
1;
