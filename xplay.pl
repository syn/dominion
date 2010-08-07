#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Storable;

use Dominion::Game;

my $game = Dominion::Game->new();
my $p1 = Dominion::Player->new(name => 'Half');
my $p2 = Dominion::Player->new(name => 'Money');
my $p3 = Dominion::Player->new(name => 'Full');
$game->player_add($p1);
$game->player_add($p2);
$game->player_add($p3);

use Dominion::Controller::AI::FullRetard;
use Dominion::Controller::AI::HalfRetard;
use Dominion::Controller::AI::DumbMoney;
Dominion::Controller::AI::HalfRetard->new(player => $p1);
Dominion::Controller::AI::DumbMoney->new(player => $p2);
Dominion::Controller::AI::FullRetard->new(player => $p3);

#my $scores = retrieve('scores.data');

$game->add_listener('gameover', sub {
    print "Game over\n";
    print "---------\n";
    my $points = {};
    my $max;
    my $mid;
    my $min;
    foreach my $player ( $game->players ) {
        my $vp = $player->deck->total_victory_points;
        $points->{$player->name}{points} = $vp;
        $max = $vp unless $max and $vp < $max;
        $min = $vp unless $min and $vp > $min;
        printf "%s => %d points (%d cards)\n", $player->name, $vp, $player->deck->count;
        my $card_count = {};
        foreach my $card ( $player->deck->cards ) {
            next unless $card->is('victory') or $card->is('curse');
            $card_count->{$card->name}++;
        }
        use Data::Dump qw(dump);
        dump($card_count);
    }
    print "got min = $min  and max = $max\n";
    print "-------------------------------------\n";
    foreach my $player (sort {$points->{$a}{points} <=> $points->{$b}{points}} keys %$points) {
        if ($points->{$player}{points} == $max) {
            print "First: ";
        }
        elsif ($points->{$player}{points} == $min) {
            print "Third: ";
        }
        else {
            print "Second: ";
        }
            print "$player got $points->{$player}{points}\n";

    }
});

$game->start;
