package Dominion::Controller;

use 5.010;
use Moose;
use Moose::Util::TypeConstraints;

with 'Dominion::EventEmitter';
use Dominion::Com::Messages;

has 'curried_callbacks' => ( # {{{
    is  => 'ro',
    isa => 'HashRef',
    default => sub {
        my ($self) = @_;

        my $curried_callbacks = {};

        foreach my $cb ( qw(action buy interaction) ) {
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
            foreach my $cb ( keys %{$self->curried_callbacks} ) {
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
		$player->add_listener('deckshuffled', sub {
			my ($p) = @_;
			$p->game->send_to_everyone(Dominion::Com::Messages::Chat->new(section => 'game', message => $p->name . "'s deck shuffle." , from => 'System'));
		});			
        

        foreach my $cb ( keys %{$self->curried_callbacks} ) {
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

sub interaction {
    my ($self, $player, $state) = @_;

    my $interaction = $state->{interaction};

    match_on_type $interaction => (
        'Dominion::Interaction::Attack' => sub {
            $self->attack($player, $state, $interaction);
        },
        'Dominion::Interaction::FreeBuy' => sub {
            $self->freebuy($player, $state, $interaction);
        },
        'Dominion::Interaction::Question' => sub {
            $self->question($player, $state, $interaction);
        },
        sub {
            die "Can't deal with interaction: " . ref $interaction;
        },
    );
}

sub attack {
    my ($self, $player, $state, $attack) = @_;
    die "Need to implement attack";
}

sub freebuy {
    die "Need to implement freebuy";
}

#__PACKAGE__->meta->make_immutable;
1;

