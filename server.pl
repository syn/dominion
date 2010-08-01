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
						}
						
						when ('finishturn') {
							$player->cleanup_phase;
							server_tick($game);
						}
						when ('finishactionphase') {
							$player->buy_phase;
							server_tick($game);
						}
						when ('playcard') {
							my $card = $game->active_player->play($message->{'card'});
							server_tick($game);
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
	            print "Game over\n";
	            print "---------\n";
	            foreach my $player ( $game->players ) {
	                my $vp = $player->deck->total_victory_points;
	                printf "%s => %d points (%d cards)\n", $player->name, $vp, $player->deck->count;
	            }
	            exit 0;
	        }
	        when ( 'action' ) {
	        	
	        	#Send a choice to the player 
				my $choice = Dominion::Com::Messages::Choice->new(message => 'Start action phase');
				my $option1 = Dominion::Com::Messages::Options::Button->new(event => 'finishactionphase', name=>'Finish Action Phase Early');
				#TODO only send the cards that can be played.
				
				my $option2 = Dominion::Com::Messages::Options::Play->new(event => 'playcard',cards => [$game->active_player->hand->cards_of_type('action')]);
				
				$choice->add($option1);
				$choice->add($option2);
				$choice->send_to_player($game->active_player);
	        }
	        when ( 'buy' ) {
	            #Send a choice to the player 
				my $choice = Dominion::Com::Messages::Choice->new(message => 'Buy phase');
				my $option1 = Dominion::Com::Messages::Options::Button->new(event => 'finishturn', name=>'Finish Buy Phase Early');
					
				my $option2 = Dominion::Com::Messages::Options::Buy->new(event => 'cardbrought',cards => [map { $_ } grep { $_->cost_coin == $state->{coin} } $game->supply->cards]);
			
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
