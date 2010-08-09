package Dominion::Game;

use 5.010;
use Moose;

with 'Dominion::EventEmitter';

use Dominion::Set::Supply;
use Dominion::Player;
use Dominion::Interaction::Attack;

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
        _player_shuffle => 'shuffle',
        player_delete   => 'delete',
    },
);
has 'set_interactions' => (
    is       => 'rw',
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Interaction]',
    default  => sub { [] },
    handles  => {
        interactions      => 'elements',
        interaction_add   => 'push',
        interaction_count => 'count',
    },
);
has 'active_player' => ( is => 'rw', isa => 'Dominion::Player' );
has 'supply' => ( is => 'ro', isa => 'Dominion::Set::Supply', default => sub { Dominion::Set::Supply->new }, required => 1 );
has 'trash' => ( is => 'ro', isa => 'Dominion::Set', default => sub { Dominion::Set->new } );
has 'inplay' => ( is => 'rw', isa => 'Bool', default => 0 );
has '_sequence' => ( is  => 'rw', isa => 'Int', default => 0 );

sub sequence_reset { shift->_sequence(0) }
sub sequence {
    my ($self) = @_;
    return $self->_sequence($self->_sequence+1);
}

after 'player_add' => sub {
    my ($self, $player) = @_;

    $player->game($self);
};

sub player_shuffle {
    my ($self) = @_;
    my @shuffled = $self->_player_shuffle;
    $self->player_clear;
    $self->player_add(@shuffled);
}

sub player_remove {
	my ($self,$player) = @_;
	#if this player is the current player
	if ($player eq $self->active_player) {
		$self->finished_turn($player);
	}
	my $i;
	for ( $i = 0; $i < $self->player_count; $i++ ) {
        last if $self->player_number($i) == $player;
    }
	$self->player_delete($i);
}

sub start {
    my ($self) = @_;

    die "Invalid number of players: " . $self->player_count unless $self->player_count >= 2 and $self->player_count <= 8;

    $self->supply->init($self->player_count);

    foreach my $player ( $self->players ) {
        $player->reset;
        $player->deck->add($self->supply->card_by_name('Copper')) for 1..7;
        $player->deck->add($self->supply->card_by_name('Estate')) for 1..3;
        $player->deck->shuffle;
        $player->hand->add($player->deck->draw(5));
        $player->actions(1);
        $player->buys(1);
        $player->coin(0);
    }

    my @players = $self->player_shuffle;
    $self->active_player(($self->players)[0]);
    $self->inplay(1);
    $self->active_player->action_phase;
}

sub remove_resolved_interactions {
    my ($self) = @_;

    my @pending_interactions = grep { not $_->resolved } $self->interactions;

    $self->set_interactions(\@pending_interactions);
}

sub tick {
    my ($self) = @_;

    my @pending;

    # Unless there's a pending action, figure out some new ones
    unless ( @pending ) {
        my $state = $self->state;
        given ( $state ) {
            when ( [qw(action buy)] ) {
                push @pending, {
                    state   => $state,
                    player  => $self->active_player,
                    id      => $self->sequence,
                };
                $self->active_player->hasticked(1);
            }
            when ('postgame') {
            	$self->emit('postgame');
            }
            when ( 'interaction' ) {
                foreach my $interaction ( $self->interactions ) {
                    push @pending, {
                        state       => $state,
                        player      => $interaction->player,
                        interaction => $interaction,
                    }
                }
            }
            default {
                die "Unknown state: $state";
            }
        }
    }

    foreach my $pending ( @pending ) {
        $pending->{player}->response_required($pending->{state}, $pending);
    }
}


sub state {
    my ($self) = @_;

    my $player = $self->active_player;
    $self->check_endgame;

    return 'pregame'  unless $player;
    return 'postgame' unless $self->inplay;
    return 'interaction' if $self->interaction_count;
    return $player->turnstate;
}

sub finished_turn {
    my ($self, $player) = @_;

    die "You can't finish a turn when it's not your turn" unless $player == $self->active_player;

    $self->active_player($self->active_player->next_player);

    $self->active_player->action_phase();
}

sub check_endgame {
    my ($self) = @_;

    my $initial_piles = $self->supply->initial_piles;
    my $current_piles = $self->supply->current_piles;
    my $empty = scalar(keys %{$initial_piles}) - scalar(keys %{$current_piles});

    return $self->endgame unless exists $current_piles->{Province};

    given ( $self->player_count ) {
        when ( 2 ) { return $self->endgame if $empty >= 2; }
        default { return $self->endgame if $empty >= 3; }
    }
}

sub endgame {
    my ($self) = @_;

    $self->inplay(0);
    foreach my $player ( $self->players ) {
        $player->discard->add($player->hand->cards);
        $player->discard->add($player->playarea->cards);
        $player->deck->add($player->discard->cards);
    }
}

sub attack {
    my ($self, $target, $callback) = @_;

    if ( $target->hand->grep(sub { $_->can('reaction') }) ) {
        $self->interaction_add(Dominion::Interaction::Attack->new(
            player   => $target,
            callback => $callback,
        ));
        return;
    }

    $callback->();
}

sub send_to_everyone {
	my ($self,$message) = @_;
	foreach my $player ($self->players) {
		$player->emit('sendmessage',$message);
	}
}

sub send_to_everyone_else {
	my ($self,$message, $player) = @_;
	foreach my $otherplayer ( $self->players ) {
		if($otherplayer ne $player) {	
			$otherplayer->emit('sendmessage',$message);
		}
	}
}

#__PACKAGE__->meta->make_immutable;
1;
