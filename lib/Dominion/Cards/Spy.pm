package Dominion::Cards::Spy;

use Moose;
extends 'Dominion::Card';

sub name        { 'Spy' }
sub tags        { qw(kingdom action attack) }
sub box         { 'Dominion' }
sub cost_coin   { 4 }
sub cost_potion { 0 }

# Attack
# +1 Card,
# +1 Action
# Each player (including you) reveals the top card of his deck and either discards it or puts it back, your choice.

sub action {
	my ( $self, $player, $game ) = @_;

	# +1 Card
	$player->hand->add( $player->draw(1) );

	# +1 action
	$player->actions_add(1);

	# First attack the other players
	foreach my $other_player ( $player->other_players ) {
		$game->attack(
			$self,
			$other_player,
			sub {
				$self->spy($player,$other_player);
			}
		);
	}
	#And spy on yourself
	$self->spy($player,$player);
}

sub spy {
	my($self,$player,$otherplayer) = @_;
	my ($card) = $otherplayer->draw(1);
	$player->game->interaction_add(
		Dominion::Interaction::Question->new(
			player  => $player,
			card    => $self,
			message => 'For '. $otherplayer->name .'s card '. $card->name. ' do you want to discard it or return it to the top of the deck',
			options => {
				0 => 'Keep it',
				1 => 'Discard',
			},
			callback => sub {
				my ($question) = @_;

				if ( $question->answer == 0 ) {
					$otherplayer->deck->add($card);
					$otherplayer->emit('revealedEveryone', $card );
				}
				else {
					$otherplayer->emit('discardEveryone', $card );
					$otherplayer->discard->add($card);
				}
			}
		)
	);
}

#__PACKAGE__->meta->make_immutable;
1;
