package Dominion::Lobby;

use Moose;
use Mojo::IOLoop;
use Dominion::Controller::Human;
use Dominion::Game;
use Data::Dumper;

has 'players' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Player]',
    default  => sub { [] },
    handles  => {
        players         => 'elements',
        player_add      => 'push',
        player_count    => 'count',
        player_number   => 'get',
        player_clear    => 'clear',
        player_delete   => 'delete',
    },
);

has 'games' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Game]',
    default  => sub { [] },
    handles  => {
        games         => 'elements',
        games_add      => 'push',
        games_count    => 'count',
        games_number   => 'get',
        games_clear    => 'clear',
        games_delete   => 'delete',
    },
);
has 'tickcount'  => ( isa => 'Int', is => 'rw', default => 0 );

after games_add => sub {
	my ($self, $game) = @_;
	$game->add_listener('playerquit' , sub {
		foreach my $player ($game->players) {
			if (!$player->isbot) {
				return;
			}
		}
		my $i;
		for ( $i = 0; $i < $self->games_count; $i++ ) {
	        last if $self->games_number($i) == $game;
	    }
		$self->games_delete($i);
	});
};
sub create_game {
	my ($self,$player,$message) = @_;
	my $game = Dominion::Game->new;
	if($message->{'name'} eq '') {
		$game->name($player->name. "'s game");
	} else {
		$game->name($message->{'name'});
	}
	$self->games_add($game);
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
	my @botnames = map { $_->{value} } @{$message->{'bots'}};
	for my $AI (@botnames) {
    	my $player = Dominion::Player->new(name => $AI);
    	$game->player_add($player);
    	"Dominion::Controller::AI::$AI"->new(player => $player);
	}
	return $game;
	
}
sub join_game {
	my ($self,$game,$player) = @_;
	
	$game->player_add($player);
    Dominion::Controller::Human->new(player => $player);
	player_connected($game,$player);
}
	


sub available_AI {
	
	
}

sub start {
	my ($self) = @_;
	$self->tick;
}


my $loop = Mojo::IOLoop->singleton;

sub tick {
	my ($self) = @_;
	$self->tickcount($self->tickcount+1);
	foreach my $game ($self->games) {
		if( $game->state ne 'postgame' && $game->state ne 'pregame' && $game->outstandingchoices == 0)  {
			print "tick\n";
			$game->tick;	
		} 
		if ( $game->state eq 'postgame' && $game->resultssent == 0) {
			$game->resultssent(1);
			$game->emit('postgame');
		}
	}
	if ($self->tickcount % 10 == 0) {
		foreach my $player ($self->players) {
			$player->emit('sendmessage',Dominion::Com::Messages::Ping->new());
		}
	}
	$loop->timer(0.25 => sub {$self->tick;});
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
sub sendlistofgames {
	my ($self,$player) = @_;
	my $json = JSON->new->utf8;
	if($self->games_count > 0) {
		$player->emit('sendmessage',Dominion::Com::Messages::ListofGames->new(games => [$self->games]));
	} else {
		$player->emit('sendmessage',Dominion::Com::Messages::ListofGames->new());
	}
}

sub getgame {
	my ($self,$id) = @_;
	foreach my $game  ($self->games){
		return $game if $game->id eq $id;
	} 
}

sub player_remove {
	my ($self,$player) = @_;
	my $i;
	for ( $i = 0; $i < $self->player_count; $i++ ) {
        last if $self->player_number($i) == $player;
    }
	$self->player_delete($i);
}

sub send_to_everyone {
	my ($self,$message) = @_;
	foreach my $player ($self->players) {
		$player->emit('sendmessage',$message);
	}
}
#__PACKAGE__->meta->make_immutable;
1;
