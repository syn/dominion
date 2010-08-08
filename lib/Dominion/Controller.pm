package Dominion::Controller;

use 5.010;
use Moose;

with 'Dominion::EventEmitter';
use Dominion::Com::Messages;

has 'curried_callbacks' => ( # {{{
    is  => 'ro',
    isa => 'HashRef',
    default => sub {
        my ($self) = @_;

        my $curried_callbacks = {};

        foreach my $cb ( qw(action buy) ) {
            $curried_callbacks->{$cb} = sub { $self->$cb(@_) };
        }
        return $curried_callbacks;
    },
); # }}}

has 'player' => (
    is       => 'rw',
    isa      => 'Dominion::Player',
    trigger  => sub {
        my ($self, $player, $old_player) = @_;

        if ( $old_player ) {
            foreach my $cb ( qw(action buy) ) {
                $old_player->remove_listener($cb, $self->curried_callbacks->{$cb});
            }
        }
        $player->add_listener('broughtcard', sub {
		    my ($p, $card) = @_;
		    $p->game->send_to_everyone_else(Dominion::Com::Messages::CardPlayed->new(actiontype => 'cardbrought', card=>$card, player=>$p),$p);
		});
		$player->add_listener('playedcard', sub {
			my ($p, $card) = @_;
		   	$p->game->send_to_everyone_else(Dominion::Com::Messages::CardPlayed->new(actiontype => 'actionplayed', card=>$card, player=>$p),$p);
		});				
        
        foreach my $cb ( qw(action buy) ) {
            $player->add_listener($cb, $self->curried_callbacks->{$cb});
        }
        $self->init;

    },
);

sub action {
    die "Need to implement action";
}

sub buy {
    die "Need to implement buy";
}

sub init {
	my ($self) = @_;
	$self->player->add_listener('turnstate', sub {
	    	my ($p,$turnstate) = @_;
	    	$p->game->send_to_everyone(Dominion::Com::Messages::PlayerStatus->new(action => $turnstate ,player=>$p));
	});
}
#__PACKAGE__->meta->make_immutable;
1;

