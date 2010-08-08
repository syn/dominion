#!/usr/bin/perl

use strict;
use warnings;
use feature qw(switch);

use Mojolicious::Lite;
use JSON;
use Data::Dumper;

use Dominion::Game;
use Dominion::Com::Messages;

use Dominion::Controller::Human;

my $game = Dominion::Game->new;
my $playercount = 0; #The number of players we have seen so far, only used for sequential initial names

$game->add_listener('postgame', sub {
   
    my @results;
	foreach my $player ( $game->players ) {
		my $vp = $player->deck->total_victory_points;
		my $res = {	name   =>  $player->name, vp => $vp };
		foreach my $card ( $player->deck->cards ) {
	    	next unless $card->is('victory') or $card->is('curse');
	        $res->{$card->name}++;
        }
		push (@results , $res);
	}
	$game->send_to_everyone(Dominion::Com::Messages::EndGame->new(results => [@results]));
	#Remove any supply listener updates that have been added, so we don't spam clients if the game is restarted and the supply is cleared.
	$game->supply->remove_all_listeners('remove');
});


use Dominion::Controller::AI::FullRetard;
use Dominion::Controller::AI::HalfRetard;
use Dominion::Controller::AI::MoneyWhore;
use Dominion::Controller::AI::DumbMoney;

foreach my $AI ( qw(MoneyWhore FullRetard HalfRetard) ) {
    my $player = Dominion::Player->new(name => $AI);
    $game->player_add($player);
    "Dominion::Controller::AI::$AI"->new(player => $player);
}

websocket '/' => sub {
	my $websocketController = shift;
	
	#create a new player..
	$playercount++; #Bump up the player count
	my $player = Dominion::Player->new(name => 'Player' . $playercount);
	$player->add_listener('sendmessage',  sub {
		my($player,$message) = @_;	
		my $json = JSON->new->utf8;
		$websocketController->send_message( $json->convert_blessed->encode($message) );
	});
    
    $game->player_add($player);
    Dominion::Controller::Human->new(player => $player);
	
	#Send Player connected message 
	#TODO make this an event
	player_connected($game,$player);
	
	# Receive message
	$websocketController->receive_message(
		sub {
			eval { 
				
				local $SIG{__DIE__} = sub { 
					my ($error) = @_;
					$player->game->send_to_everyone(Dominion::Com::Messages::Chat->new(message => 'ERROR processing ' . $player->name . ' : ' . $error, from => 'Server'));
		    	};
				my ( $self, $rawmessage ) = @_;
				my $message = decode_json($rawmessage);
				given($message->{'type'}) {
					when ('message')    {chat_message($player->game,$player,$message);}
					when ('namechange') {name_change($player,$message->{'name'});}
					when ('startgame')  {
						#Send everyone a message telling them that game has started.
						$player->game->send_to_everyone(Dominion::Com::Messages::StartGame->new());
						
						$player->game->start;
						gametick($game);
						#add a listener to send a new supply out to everyone if it changes
						$game->supply->add_listener('remove',sub {$player->game->send_to_everyone(Dominion::Com::Messages::Supply->new(supply => $game->supply));});
						
					}
					when ('choiceresponse') {
						given($message->{'event'}) {
							when ('cardbrought') {
								$player->buy($message->{'card'});
								gametick($game);
								return;
							}
							
							when ('finishturn') {
								$player->cleanup_phase;
								gametick($game);
								return;
							}
							when ('finishactionphase') {
								$player->buy_phase;
								gametick($game);
								return;
							}
							when ('playcard') {
								$player->play($message->{'card'});
								gametick($game);
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
			#TODO remove the player from the game
			
		}
	);
};

sub gametick {
	my($game) = @_;
	my $hack = 0;
	do {
		if($game->active_player->isbot) {$hack++};
		$game->tick;
	} while ( $game->state ne 'postgame' && $game->active_player->isbot) ;
	
	if ($hack) {
		$game->tick;
	}
}

sub player_connected {
	my ($game,$player) = @_;

	#Send some game state.
	$player->emit('sendmessage',Dominion::Com::Messages::InitialSetup->new(gamestatus => $game->state , name => $player->name));
    
	#Send everyone else a message that the player joined the game.
	$player->game->send_to_everyone(Dominion::Com::Messages::PlayerStatus->new(action => 'joined' ,player=>$player));
	#Send this player a message about everyone else who is in the game
	 foreach my $otherplayer ( $player->game->players ) {
     	if($player!=$otherplayer) {
     		$player->emit('sendmessage',Dominion::Com::Messages::PlayerStatus->new(action => 'joined' ,player=>$otherplayer));
     	}
    }
}


sub chat_message {
	my ($game,$player,$incomingmessag) = @_;
	$game->send_to_everyone(Dominion::Com::Messages::Chat->new(message => $incomingmessag->{'message'} , from => $player->name));
}

sub name_change {
	my ($player, $n) = @_;
	$player->name($n);
	$player->game->send_to_everyone(Dominion::Com::Messages::PlayerStatus->new(action => 'namechange' ,  player => $player)); 
}

get '/' => 'index';

app->start;

1;
