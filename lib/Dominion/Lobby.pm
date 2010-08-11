package Dominion::Lobby;

use Moose;

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

#__PACKAGE__->meta->make_immutable;
1;
