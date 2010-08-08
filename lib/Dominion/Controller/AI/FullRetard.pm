package Dominion::Controller::AI::FullRetard;

use Moose;

extends 'Dominion::Controller::AI';

sub action {
    my ($self, $player, $state) = @_;

    my $card_name = ($player->hand->cards_of_type('action'))[0]->name;
    $player->play($card_name);
}

sub buy {
    my ($self, $player, $state) = @_;

    my $game = $player->game;

    my $coin = $player->coin;
    while ( $coin >= 0 ) {
        my @card_names = map { $_->name } grep { $_->cost_coin == $coin } $game->supply->cards;
        unless ( @card_names ) {
            $coin--;
            next;
        }
        my $card_name = @card_names[int rand() * @card_names];
        $player->buy($card_name);
        last;
    }
}

sub init {
	my ($self) = @_;
	$self->SUPER::init();
	$self->player->add_listener('sendmessage',  sub {
		my($player,$message) = @_;	
		if($message->type eq 'message' && int rand()* 10 == 1) {
			$self->player->game->send_to_everyone_else(Dominion::Com::Messages::Chat->new(message => 'So is your face.', from => $player->name) , $self->player);
		}
	});
}	

#__PACKAGE__->meta->make_immutable;
1;
