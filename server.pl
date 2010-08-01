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
					
				}
#				when ('choiceresponse') {
#					given($message->{'event'}) {
#						when ('cardbrought') {$player->buy_card($message->{'card'})}
#						when ('finishturn') {$player->cleanup_phase}
#						when ('finishactionphase') {$player->buy_phase}
#						when ('playcard') {
#							if($game->supply->find_card($message->{'card'})->play($player)) {
#								$player->action_phase;
#							};
#						}
#						default {print Dumper($message);}
#					}
#				}			
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