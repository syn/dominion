#!/usr/bin/perl

use strict;
use warnings;
use feature qw(switch);

use Mojolicious::Lite;
use JSON;
use Data::Dumper;

use Dominion::Game;
use Dominion::Com::Messages;


my $clients     = {};  #List of all clients.
my $game = Dominion::Game->new;
my $playercount = 0; #The number of players we have seen so far, only used for sequential initial names

websocket '/' => sub {
	my $self = shift;
	
	#create a new player..
	$playercount++; #Bump up the player count
	my $player = Dominion::Player->new(name => 'Player' . $playercount, controller => $self);
	
	
	
	#add a listener that sends the player thier hand whenever they get a card
	$player->hand->add_listener('add', sub {
        send_hand($player);
    });
    #add a listener that sends out the players state whenever it changes
    $player->add_listener('turnstate', sub {
    	my ($p,$turnstate) = @_;
    	Dominion::Com::Messages::PlayerStatus->new(action => $turnstate ,player=>$p)->send_to_everyone($game);
    });
    
	$game->player_add($player);
	#Send Player connected message
	player_connected($game,$player);
	# Receive message
	$self->receive_message(
		sub {
			my ( $self, $rawmessage ) = @_;
			my $message = decode_json($rawmessage);
			given($message->{'type'}) {
				when ('message')    {chat_message($game,$player,$message);}
				when ('namechange') {name_change($player,$message->{'name'});}
				when ('startgame')  {
					$game->start;
					#Send everyone a message telling them that game has started.
					Dominion::Com::Messages::StartGame->new()->send_to_everyone($game);
					
					#send the supply to all the players
					Dominion::Com::Messages::Supply->new(supply => $game->supply)->send_to_everyone($game); 
					#add a listener to send a new supply out to everyone if it changes
					$game->supply->add_listener('remove',sub {Dominion::Com::Messages::Supply->new(supply => $game->supply)->send_to_everyone($game);});
					server_tick($game);
				}
				when ('choiceresponse') {
					given($message->{'event'}) {
						when ('cardbrought') {
							my $p = $game->active_player; #have to save the active_player here, the buy function will change it on us
							my $card = $game->active_player->buy($message->{'card'});
							#Tell everyone that you brought a card
							Dominion::Com::Messages::CardPlayed->new(actiontype => 'cardbrought', card=>$card, player=>$p)->send_to_everyone_else($p);
							server_tick($game);
							return;
						}
						
						when ('finishturn') {
							my $p = $game->active_player;
							$player->cleanup_phase;
							server_tick($game);
							return;
						}
						when ('finishactionphase') {
							my $p = $game->active_player;
							$player->buy_phase;
							server_tick($game);
							return;
						}
						when ('playcard') {
							my $p = $game->active_player;
							my $card = $game->active_player->play($message->{'card'});
							#Tell everyone that you played a card
							Dominion::Com::Messages::CardPlayed->new(actiontype => 'actionplayed', card=>$card, player=>$p)->send_to_everyone_else($p);
							server_tick($game);
							return;
						}
						default {print Dumper($message);}
					}
				}			
				default {print Dumper($message);}
			}			
		}
	);
		
	# Finished
	$self->finished(
		sub {
			#TODO remove the player from the game
			
		}
	);
};


sub server_tick {
	my ($game) = @_;
	print "Server Tick\n";
	if ( $game->active_player ) {
		
	    my $state = $game->state;
		print Dumper($state);
	    given ( $state->{state} ) {
	        when ( 'gameover' ) {
	            my @results;
	            foreach my $player ( $game->players ) {
					my $vp = $player->deck->total_victory_points;
					my $res = {	name   =>  $player->name, vp => $vp };
					foreach my $card ( $player->deck->cards ) {
	                    next unless $card->is('victory');
	                    $res->{$card->name}++;
                	}
					push (@results , $res);
				}
				Dominion::Com::Messages::EndGame->new(results => [@results])->send_to_everyone($game);
	        }
	        when ( 'action' ) {
	        	
	        	#Send a choice to the player 
				my $choice = Dominion::Com::Messages::Choice->new(message => 'Action phase : actions = ' . $state->{actions} );
				my $option1 = Dominion::Com::Messages::Options::Button->new(event => 'finishactionphase', name=>'Finish Action Phase Early');
				#TODO only send the cards that can be played.
				
				my $option2 = Dominion::Com::Messages::Options::Play->new(event => 'playcard',cards => [$game->active_player->hand->cards_of_type('action')]);
				
				$choice->add($option1);
				$choice->add($option2);
				$choice->send_to_player($game->active_player);
	        }
	        when ( 'buy' ) {
	            #Send a choice to the player 
				my $choice = Dominion::Com::Messages::Choice->new(message => 'Buy phase : buys = ' . $state->{buys} . ' , gold = ' . $state->{coin});
				my $option1 = Dominion::Com::Messages::Options::Button->new(event => 'finishturn', name=>'Finish Buy Phase Early');
					
				my $option2 = Dominion::Com::Messages::Options::Buy->new(event => 'cardbrought',cards => [map { $_ } grep { $_->cost_coin <= $state->{coin} } $game->supply->cards]);
			
				$choice->add($option1);
				$choice->add($option2);
				$choice->send_to_player($game->active_player);
	        }
	        default { die "Can't deal with state: $state->{state}" }
	    }
	}
}


sub player_connected {
	my ($game,$p) = @_;

	#Send some game state.
	Dominion::Com::Messages::InitialSetup->new(gamestatus => $game->state->{'state'} , name => $p->name)->send_to_player($p);
    
	#Send everyone else a message that the player joined the game.
	Dominion::Com::Messages::PlayerStatus->new(action => 'joined' ,player=>$p)->send_to_everyone($game);
	#Send this player a message about everyone else who is in the game
	 foreach my $player ( $game->players ) {
     	if($player!=$p) {
     		my $c = Dominion::Com::Messages::PlayerStatus->new(action => 'joined' ,player=>$player);
     		$c->send_to_player($p);
     	}
    }
}

sub send_hand {
	my ($player) = @_;	
	my $c = Dominion::Com::Messages::Hand->new(cards => $player->hand);
	$c->send_to_player($player);
}
sub chat_message {
	my ($game,$p,$incomingmessag) = @_;
	my $c = Dominion::Com::Messages::Chat->new(message => $incomingmessag->{'message'} , from => $p->name);
	$c->send_to_everyone($game);
}

sub name_change {
	my ($player, $n) = @_;
	$player->name($n);
	
	#TODO, set a playerID
	my $c = Dominion::Com::Messages::PlayerStatus->new(action => 'namechange' ,  player => $player);
	$c->send_to_everyone($player->game); 
}

get '/' => 'index';

app->start;

1;
