#!/usr/bin/perl

use strict;
use warnings;
use feature qw(switch);

use Mojolicious::Lite;
use JSON;
use Data::Dumper;

use Dominion::Game;
my $clients     = {};  #List of all clients.
my $game = Dominion::Game->new;
my $playercount = 0; #The number of players we have seen so far, exists give new players a unique name.

websocket '/' => sub {
	my $self = shift;
	
	#create a new player..
	$playercount++; #Bump up the player count
	my $player = Dominion::Player->new(name => 'Player' . $playercount, controller => $self , id => $playercount , game => $game);
	$game->player_add($player);
	$game->player_connected($player);
	# Receive message
	$self->receive_message(
		sub {
			my ( $self, $rawmessage ) = @_;
			my $message = decode_json($rawmessage);
			given($message->{'type'}) {
				when ('message')    {$game->chat_message($player,$message);}
				when ('namechange') {$player->name_change($message->{'name'});}
				when ('startgame')  {$game->start;}
				when ('choiceresponse') {
					given($message->{'event'}) {
						when ('cardbrought') {$player->buy_card($message->{'card'})}
						when ('finishturn') {$player->cleanup_phase}
						when ('finishactionphase') {$player->buy_phase}
						when ('playcard') {
							if($game->supply->find_card($message->{'card'})->play($player)) {
								$player->action_phase;
							};
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


get '/' => 'index';

app->start;

1;
