package Dominion::Controller;

use 5.010;
use Moose;
no warnings 'recursion';

with 'Dominion::EventEmitter';

has 'curried_callbacks' => ( # {{{
    is  => 'ro',
    isa => 'HashRef',
    default => sub {
        my ($self) = @_;

        my $curried_callbacks = {};

        foreach my $cb ( qw(response_required) ) {
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
            $old_player->remove_listener('response_required', $self->curried_callbacks->{response_required});
        }
        $player->add_listener('response_required', $self->curried_callbacks->{response_required});
        
        $player->add_listener('broughtcard', sub {
		    my ($p, $card) = @_;
		    $p->game->send_to_everyone_else(Dominion::Com::Messages::CardPlayed->new(actiontype => 'cardbrought', card=>$card, player=>$p),$p);
		});
		$player->add_listener('playedcard', sub {
			my ($p, $card) = @_;
		   	$p->game->send_to_everyone_else(Dominion::Com::Messages::CardPlayed->new(actiontype => 'actionplayed', card=>$card, player=>$p),$p);
		});				
        
        $self->init;
    },
);

sub response_required {
    my $self = shift;
    my ($player, $state) = @_;

    print "WTF!\n" unless $player->name eq $self->player->name;

    given ( $state->{state} ) {
        when ( 'action' ) { $self->action(@_) }
        when ( 'buy' ) { $self->buy(@_) }
        default { die "Don't know how to deal with state: $state->{state}" }
    }
}

sub action {
    die "Need to implement action";
}

sub buy {
    die "Need to implement buy";
}

sub init {
	
}
#__PACKAGE__->meta->make_immutable;
1;

