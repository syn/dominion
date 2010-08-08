package Dominion::Controller::Human;

use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use List::Util qw(shuffle);
no warnings 'recursion';

extends 'Dominion::Controller';


has 'buycount' => ( is => 'rw', isa => 'Int', default => 0 ); 

sub init {
	my ($self) = @_;
    	#add a listener that sends out the players state whenever it changes
	    $self->player->add_listener('turnstate', sub {
	    	my ($p,$turnstate) = @_;
	    	$p->game->send_to_everyone(Dominion::Com::Messages::PlayerStatus->new(action => $turnstate ,player=>$p));
	    });
    	
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

sub interaction {
	my ( $self, @data ) = @_;
	my $state       = $data[1];
	my $interaction = $data[2];
	print "Handling interaction " . $interaction->cause . "\n";

	my $choice = Dominion::Com::Messages::Choice->new(message => 'Resolve '  . $interaction->cause);
	#Look through the interaction option list
	foreach my $option ( $interaction->options )
	{
		match_on_type $option => (
			'Dominion::Interactions::Discard'  => sub { 
				my $o =Dominion::Com::Messages::Options::Discard->new(event => 'discardinteraction',numbertodiscard => $option->numbertodiscard,cards => [$option->cards]);
				$choice->add($o);
			},
		),
	}
	$self->player->emit('sendmessage',$choice);
}

sub send_hand {
	my ($self) = @_;	
	$self->player->emit('sendmessage',Dominion::Com::Messages::Hand->new(cards => $self->player->hand));
}
#__PACKAGE__->meta->make_immutable;
1;