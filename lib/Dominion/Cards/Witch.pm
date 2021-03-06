package Dominion::Cards::Witch;

use Moose;
extends 'Dominion::Card';

sub name        { 'Witch' }
sub tags        { qw(kingdom action attack) }
sub box         { 'Dominion' }
sub cost_coin   { 5 }
sub cost_potion { 0 }

sub action {
    my ($self, $player, $game) = @_;

    # +2 Card
    $player->hand->add($player->draw(2));

    # Each other player gains a curse
    foreach my $other_player ( $player->other_players ) {
        $game->attack($self, $other_player, sub {
            my $curse = $game->supply->card_by_name('Curse');
            if ($curse) {
            	$other_player->discard->add($curse) if $curse;
            	$other_player->game->send_to_everyone(Dominion::Com::Messages::CardPlayed->new(actiontype => 'witchresolve', card=>$curse, player=>$other_player));
            }
        });
    }
}


#__PACKAGE__->meta->make_immutable;
1;
