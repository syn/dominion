package Dominion::Controller::AI::DumbMoney;

use 5.010;
use Moose;
use List::Util qw(shuffle);
no warnings 'recursion';

extends 'Dominion::Controller::AI';

has 'buycount' => ( is => 'rw', isa => 'Int', default => 0 );

sub action {
    my ($self, $player, $state) = @_;

    my $card_name = ($player->hand->cards_of_type('action'))[0]->name;
    $player->play($card_name);
}

sub buy {
    my ($self, $player, $state) = @_;

    $self->buycount($self->buycount+1);

    my $game = $player->game;

    my $coin = $state->{coin};
    my $card;

    my @list;
    given ( $coin ) {
        # 1-2: No buy
        # 3-5: Buy silver
        # 6-7: Buy gold
        # 8+: Buy Province
        when ( 0 ) { return $player->cleanup_phase(); }
        when ( 1 ) { return $player->cleanup_phase(); }
        when ( 2 ) { return $player->cleanup_phase(); }
        when ( 3 ) {
            @list = qw(Silver);
        }
        when ( 4 ) {
            @list = qw(Silver);
        }
        when ( 5 ) {
            @list = qw(Silver);
        }
        when ( 6 ) {
            @list = qw(Gold);
        }
        when ( 7 ) {
            @list = qw(Gold);
        }
        when ( $_ > 7 ) {
            @list = qw(Province);
        }
    }
    if ( @list ) {
        foreach my $potential ( @list ) {
            ($card) //= $game->supply->card_by_name($potential);
        }
    }

    $card //= do {
        while ( $coin >= 0 ) {
            my @cards = grep { $_->cost_coin == $coin } $game->supply->cards;
            unless ( @cards ) {
                $coin--;
                next;
            }
            $card = @cards[int rand() * @cards];
            last;
        }
        $card;
    };

    print "Buying: ", $card->name, "\n";
    print "-------\n";
    $player->buy($card->name);
}

sub attack {
    my ($self, $player, $game, $attack) = @_;
    $attack->done();
}
#__PACKAGE__->meta->make_immutable;
1;
