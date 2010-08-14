package Dominion::Controller::Human;

use 5.010;
use Moose;
use List::Util qw(shuffle);
no warnings 'recursion';

extends 'Dominion::Controller';


has 'buycount' => ( is => 'rw', isa => 'Int', default => 0 ); 



sub init {
	my ($self) = @_;
	$self->SUPER::init();
    	#add a listener that sends out the players state whenever it changes
	    
    	$self->player->hand->add_listener('add', sub {
        	$self->send_hand;
	    });
	    $self->player->hand->add_listener('remove', sub {
	        $self->send_hand;
	    });
	    
	    
	    $self->player->game->supply->add_listener('newsupply',sub {
    		$self->player->emit('sendmessage',Dominion::Com::Messages::Supply->new(supply => $self->player->game->supply)); 
    	});
}

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
	$self->player->game->outstandingchoices($self->player->game->outstandingchoices+1);
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
	$self->player->game->outstandingchoices($self->player->game->outstandingchoices+1);
}

sub attack {
    my ($self, $player, $state, $attack) = @_;

    return $attack->done if $attack->cancelled;

	if ($player->hand->cards_of_type('reaction')) {
		$self->player->currentinteraction($attack);
		#Send a choice to the player 
		my $choice = Dominion::Com::Messages::Choice->new(message => 'Attack Reaction' );
		my $option1 = Dominion::Com::Messages::Options::Button->new(event => 'interactionfinish', name=>"Finished reacting");
		my $option2 = Dominion::Com::Messages::Options::Play->new(event => 'interactioncard',cards => [$player->hand->cards_of_type('reaction')],reveal => 'true');
		
		$choice->add($option1);
		$choice->add($option2);
		$self->player->emit('sendmessage',$choice);		
		$self->player->game->outstandingchoices($self->player->game->outstandingchoices+1);
	} else {
		return $attack->done;
	}
}

sub freebuy {
    my ($self, $player, $game, $interaction) = @_;
    $self->player->currentinteraction($interaction);
    my $choice = Dominion::Com::Messages::Choice->new(message => $interaction->message );
	my $option1 = Dominion::Com::Messages::Options::Button->new(event => 'interactionfinish', name=>"Finished reacting");
	my $option2 = Dominion::Com::Messages::Options::Buy->new(event => 'interactioncard',cards => [$interaction->cards],reveal => 'false');
	$choice->add($option1);
	$choice->add($option2);
	$self->player->emit('sendmessage',$choice);		
	$self->player->game->outstandingchoices($self->player->game->outstandingchoices+1);
}

sub send_hand {
	my ($self) = @_;	
	$self->player->emit('sendmessage',Dominion::Com::Messages::Hand->new(cards => $self->player->hand));
}


#__PACKAGE__->meta->make_immutable;
1;
