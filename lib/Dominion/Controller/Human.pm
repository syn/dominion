package Dominion::Controller::Human;

use 5.010;
use Moose;
use List::Util qw(shuffle);
no warnings 'recursion';

extends 'Dominion::Controller';


has 'buycount' => ( is => 'rw', isa => 'Int', default => 0 ); 
has 'player' => (
    is       => 'rw',
    isa      => 'Dominion::Player',
    trigger  => sub {
        my ($self, $player, $old_player) = @_;

        if ( $old_player ) {
            $old_player->remove_listener('response_required', $self->curried_callbacks->{response_required});
        }
        $player->add_listener('response_required', $self->curried_callbacks->{response_required});
    	#add a listener that sends out the players state whenever it changes
	    $player->add_listener('turnstate', sub {
	    	my ($p,$turnstate) = @_;
	    	send_to_everyone(Dominion::Com::Messages::PlayerStatus->new(action => $turnstate ,player=>$p),$p->game);
	    });
    	
    	$player->hand->add_listener('add', sub {
        	$self->send_hand;
	    });
	    $player->hand->add_listener('remove', sub {
	        $self->send_hand;
	    });
	    
	    $player->add_listener('broughtcard', sub {
	    	my ($p, $card) = @_;
	    	send_to_everyone_else(Dominion::Com::Messages::CardPlayed->new(actiontype => 'cardbrought', card=>$card, player=>$p),$p);
	    });
	    $player->add_listener('playedcard', sub {
	    	my ($p, $card) = @_;
	    	send_to_everyone_else(Dominion::Com::Messages::CardPlayed->new(actiontype => 'actionplayed', card=>$card, player=>$p),$p);
	    });
	    
	    $player->game->supply->add_listener('newsupply',sub {
    		$self->player->emit('sendmessage',Dominion::Com::Messages::Supply->new(supply => $player->game->supply)); 
    	});
    
    },
);


sub action {
    my ($self, $player, $state) = @_;
    
    #Send a choice to the player 
	my $choice = Dominion::Com::Messages::Choice->new(message => 'Action phase : actions = ' . $state->{actions} );
	my $option1 = Dominion::Com::Messages::Options::Button->new(event => 'finishactionphase', name=>'Finish Action Phase Early');
	#TODO only send the cards that can be played.
	
	my $option2 = Dominion::Com::Messages::Options::Play->new(event => 'playcard',cards => [$player->hand->cards_of_type('action')]);
	
	$choice->add($option1);
	$choice->add($option2);
	$self->player->emit('sendmessage',$choice);
}

sub buy {
    my ($self, $player, $state) = @_;

    $self->buycount($self->buycount+1);

    my $game = $player->game;
    
    #Send a choice to the player 
	my $choice = Dominion::Com::Messages::Choice->new(message => 'Buy phase : buys = ' . $state->{buys} . ' , gold = ' . $state->{coin});
	my $option1 = Dominion::Com::Messages::Options::Button->new(event => 'finishturn', name=>'Finish Buy Phase Early');
		
	my $option2 = Dominion::Com::Messages::Options::Buy->new(event => 'cardbrought',cards => [map { $_ } grep { $_->cost_coin <= $state->{coin} } $game->supply->cards]);

	$choice->add($option1);
	$choice->add($option2);
	$self->player->emit('sendmessage',$choice);
}

sub send_hand {
	my ($self) = @_;	
	$self->player->emit('sendmessage',Dominion::Com::Messages::Hand->new(cards => $self->player->hand));
}

sub send_to_everyone_else {
	my ($self, $message) = @_;
	foreach my $otherplayer ( $self->player->game->players ) {
		if($self->player ne $otherplayer) {
			$otherplayer->emit('sendmessage',$message);
		}
	}
}

sub send_to_everyone {
	my ($message, $game) = @_;
	foreach my $player ($game->players) {
		$player->emit('sendmessage',$message);
	}
}
 
#__PACKAGE__->meta->make_immutable;
1;
