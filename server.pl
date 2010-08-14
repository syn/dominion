#!/usr/bin/perl

use strict;
use warnings;
use feature qw(switch);

use Mojolicious::Lite;

use JSON;
use Data::Dumper;


use Dominion::Lobby;
use Dominion::Com::Messages;

my $lobby = Dominion::Lobby->new;
$lobby->start;

my $playercount = 0; #The number of players we have seen so far, only used for sequential initial names

websocket '/' => sub {
	my $websocketController = shift;
	
	#create a new player..
	$playercount++; #Bump up the player count
	my $player = Dominion::Player->new(name => 'Player' . $playercount);
	$lobby->player_add($player);
	$player->add_listener('sendmessage',  sub {
		my($player,$message) = @_;	
		my $json = JSON->new->utf8;
		$websocketController->send_message( $json->convert_blessed->encode($message) );
	});	
	# Receive message
	$websocketController->receive_message(
		sub {
			eval { 
				
				local $SIG{__DIE__} = sub { 
					my ($error) = @_;
					$lobby->send_to_everyone(Dominion::Com::Messages::Chat->new(message => 'ERROR processing ' . $player->name . ' : ' . $error, from => 'Server'));
		    	};
				my ( $self, $rawmessage ) = @_;
				my $message = decode_json($rawmessage);
				given($message->{'type'}) {
					when ('message')    {chat_message($lobby,$player,$message);}
					when ('namechange') {name_change($player,$message->{'name'});}
					when ('creategame') {
						my $game = $lobby->create_game($player,$message);
						$lobby->join_game($game,$player);
						return;
					}
					when ('joingame') {
						my $game = $lobby->getgame($message->{'gameid'});
						$lobby->join_game($game,$player);
						return;
					}
					when ('listofgames') {
						print "Got a request for a list of games\n";
						$lobby->sendlistofgames($player);
						return;
					}
					when ('startgame')  {
						#Send everyone a message telling them that game has started.
						$player->game->send_to_everyone(Dominion::Com::Messages::StartGame->new());
						$player->game->start;
						gametick($player->game);
						#add a listener to send a new supply out to everyone if it changes
						$player->game->supply->add_listener('remove',sub {$player->game->send_to_everyone(Dominion::Com::Messages::Supply->new(supply => $player->game->supply));});
						return;
					}
					when ('choiceresponse') {
						$player->game->outstandingchoices($player->game->outstandingchoices-1);
						given($message->{'event'}) {
							when ('cardbrought') {
								$player->buy($message->{'card'});
								gametick($player->game);
								return;
							}
							when ('finishturn') {
								$player->cleanup_phase;
								gametick($player->game);
								return;
							}
							when ('finishactionphase') {
								$player->buy_phase;
								gametick($player->game);
								return;
							}
							when ('playcard') {
								$player->play($message->{'card'});
								gametick($player->game);
								return;
							}
							when ('interactionfinish') {
								$player->currentinteraction->done;
								#do I need to tick here?
								return;
							}
							when ('interactioncard') {
								$player->currentinteraction->play($message->{'card'});
								$player->currentinteraction->done;
								#do I need to tick here?
								return;
							}
							default {print Dumper($message);}
						}
					}			
					default {print Dumper($message);}
				}			
			}
		}
	);
		
	# Finished
	$websocketController->finished(
		sub {
			if($player->game) {			
				$player->game->send_to_everyone_else(Dominion::Com::Messages::PlayerStatus->new(action => 'quit' ,player=>$player));
				$player->game->player_remove($player);
				$lobby->player_remove($player);
			}			
		}
	);
};

sub gametick {
	my ($game) = @_;
	$game->tick;
}

sub chat_message {
	my ($lobby,$player,$incomingmessag) = @_;
	#if($incomingmessag->{'area'} eq 'game') {
	#	$player->game->send_to_everyone(Dominion::Com::Messages::Chat->new(message => $incomingmessag->{'message'} , from => $player->name));
	#} else {
		$lobby->send_to_everyone(Dominion::Com::Messages::Chat->new(section => 'lobby', message => $incomingmessag->{'message'} , from => $player->name));
	#}
}

sub name_change {
	my ($player, $n) = @_;
	$player->name($n);
	if($player->game) {
		$player->game->send_to_everyone(Dominion::Com::Messages::PlayerStatus->new(action => 'namechange' ,  player => $player));
	} 
}

get '/' => 'index';

app->start;

1;
