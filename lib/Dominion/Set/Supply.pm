package Dominion::Set::Supply;

use 5.010;

use Moose;
extends 'Dominion::Set';
with 'Dominion::EventEmitter';

use List::MoreUtils qw(uniq);

has 'initial_piles' => ( is => 'rw', isa => 'HashRef' );

use Dominion::Cards;

sub init {
    my ($self, $player_count) = @_;

    die "Must specify number of players" unless defined $player_count;
    die "Player count must be between 2 and 8" unless $player_count >= 2 and $player_count <= 8;

    $self->clear;

    my %card_count_for = (
        'Dominion::Cards::Estate'   => 12,
        'Dominion::Cards::Duchy'    => 12,
        'Dominion::Cards::Province' => 12,
        'Dominion::Cards::Curse'    => 30,
        'Dominion::Cards::Copper'   => 60,
        'Dominion::Cards::Silver'   => 40,
        'Dominion::Cards::Gold'     => 30,
    );

    given ( $player_count ) {
        # See page 4 of the Dominion rules
        when (2) {
            $card_count_for{'Dominion::Cards::Estate'}   = 8 + 6; # 2 players 3 each
            $card_count_for{'Dominion::Cards::Duchy'}    = 8;
            $card_count_for{'Dominion::Cards::Province'} = 8;
            $card_count_for{'Dominion::Cards::Curse'}    = 10;
        }
        when (3) {
            $card_count_for{'Dominion::Cards::Estate'} = 12 + 9; # 3 players 3 each
            $card_count_for{'Dominion::Cards::Curse'}  = 20;
        }
        when (4) {
            $card_count_for{'Dominion::Cards::Estate'} = 12 + 12; # 4 players 3 each
        }
        # These counts are recommended in the Intrigue rules
        when (5) {
            $card_count_for{'Dominion::Cards::Estate'}   = 12 + 15; # 5 players 3 each
            $card_count_for{'Dominion::Cards::Province'} = 15;
            $card_count_for{'Dominion::Cards::Curse'}    = 40;
        }
        when (6) {
            $card_count_for{'Dominion::Cards::Estate'}   = 12 + 18; # 6 players 3 each
            $card_count_for{'Dominion::Cards::Province'} = 18;
            $card_count_for{'Dominion::Cards::Curse'}    = 50;
        }
    }

    foreach my $card ( keys %card_count_for ) {
        $self->add(map { $card->new   } 1 .. $card_count_for{$card});
    }

    my $kingdoms = Dominion::Set->new();
    $kingdoms->add(map { $_->new } grep { $_->can('action') || $_->can('victory_points') } Dominion::Cards->kingdom);
    $kingdoms->shuffle;
    foreach my $kingdom ( $kingdoms->draw(10) ) {
        next unless $kingdom;
        #The rules say if the kingdom card is a victory card too, then we use the same number as there are provinces in the game
        my $count = $kingdom->is('victory') ? $card_count_for{'Dominion::Cards::Province'} : 10;
        $self->add(map { (ref $kingdom)->new } 1..$count);
    }
    my $initial_piles = $self->initial_piles({});
    foreach my $card ( $self->cards ) {
        $initial_piles->{$card->name} //= 0;
        $initial_piles->{$card->name}++;
    }
    $self->emit('newsupply');
}

sub current_piles {
    my ($self) = @_;

    my $piles = {};
    foreach my $card ( $self->cards ) {
        $piles->{$card->name} //= 0;
        $piles->{$card->name}++;
    }
    return $piles;
}



#Builds a summary of the supply suitable for sending to the client.
sub summary {
    my ($self) = @_;

    my %data;

    foreach my $card ( $self->cards ) {
        if(exists ($data{$card->name})) {
        	$data{$card->name}->count($data{$card->name}->count+1);
        } else {
        	$data{$card->name} = $card->new;
        }
    }
 	return sort sortcards (values %data);
}
sub sortcards {
	if( $a->group != $b->group) {
		return $a->group <=> $b->group;
	}
	return $a->cost_coin <=> $b->cost_coin;
}

sub TO_JSON {
	my ($self) = @_;
	my $data;
	return [$self->summary];
}

#__PACKAGE__->meta->make_immutable;
1;
