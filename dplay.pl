#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Dominion::Game;
use Data::Dump qw(dump);

use ExtUtils::MakeMaker qw(prompt);

my $game = Dominion::Game->new();
my $p1 = Dominion::Player->new(name => 'Martyn');
my $p2 = Dominion::Player->new(name => 'Fred');
my $p3 = Dominion::Player->new(name => 'Harold');
$game->player_add($p1);
$game->player_add($p2);
$game->player_add($p3);
$game->start;

my $debug = 0;
my $interactive = 0;

my $last_player;

my %turncount;
my $current_turn;
map {
    $_->add_listener('turnstate', sub {
        my ($player, $turnstate) = @_;
        if ($last_player ne $player->name) {
            print "\n";
            $turncount{$player->name}++;
        }
        $last_player = $player->name;
        print "--------- TURN " . $turncount{$player->name} . "---------\n\n" unless $current_turn == $turncount{$player->name};
        $current_turn = $turncount{$player->name};
        print $player->name, " => ", $turnstate, "\n";
    })
} ($p1, $p2, $p3);

map {
    $_->hand->add_listener('add', sub {
        my ($set, @cards) = @_;
        print "added to hand: ", join(', ', map { $_->name } @cards), "\n";
    });
} ($p1, $p2, $p3);

map {
    $_->hand->add_listener('remove', sub {
        my ($set, @cards) = @_;
        print "removed from hand: ", join(', ', map { $_->name } @cards), "\n";
    });
} ($p1, $p2, $p3);

$p1->hand->add_listener('add', sub {
    my ($set, @cards) = @_;
    #print "Martyn added to hand: ", join(', ', map { $_->name } @cards), "\n";
});

$p1->hand->add_listener('remove', sub {
    my ($set, @cards) = @_;
    #print "Martyn removed from hand: ", join(', ', map { $_->name } @cards), "\n";
});

my $count = 0;
while ( 1 ) {
    my $next = prompt('>') if $interactive;

    my $state = $game->state;

    dump($state) if $debug;

    given ( $state->{state} ) {
        when ( 'pregame' ) {
        }
        when ( 'gameover' ) {
            print "Game over\n";
            print "---------\n";
            foreach my $player ( $game->players ) {
                my $vp = $player->deck->total_victory_points;
                printf "%s => %d points (%d cards)\n", $player->name, $vp, $player->deck->count;
                my $card_count = {};
                foreach my $card ( $player->deck->cards ) {
                    next unless $card->is('victory');
                    $card_count->{$card->name}++;
                }
                dump($card_count);
            }
            exit 0;
        }
        when ( 'action' ) {
            my $card_name = ($game->active_player->hand->cards_of_type('action'))[0]->name;
            print $game->active_player->name . " plays $card_name\n";
            $game->active_player->play($card_name);
            $last_player = $game->active_player->name;
        }
        when ( 'buy' ) {
            my $coin = $state->{coin};
            while ( $coin >= 0 ) {
                my @card_names = map { $_->name } grep { $_->cost_coin == $coin } $game->supply->cards;
                unless ( @card_names ) {
                    $coin--;
                    next;
                }
                my $card_name = @card_names[int rand() * @card_names];
                print $game->active_player->name . " buys $card_name\n";
                $last_player = $game->active_player->name;
                $game->active_player->buy($card_name);
                last;
            }
        }
        default { die "Can't deal with state: $state->{state}" }
    }
}
