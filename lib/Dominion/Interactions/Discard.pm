package Dominion::Interactions::Discard;

use Moose;
extends 'Dominion::Interaction';

has '+type'      => default => 'discard';
has 'numbertodiscard'      => (isa => 'Int' , is => 'rw' , required => 1 , default => 1);
has 'cards' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Card]',
    default  => sub { [] },
    handles  => {
        add      => 'push',
        cards    => 'elements',
        count    => 'count',
        get      => 'get',
    },
);

has 'discards' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Card]',
    default  => sub { [] },
    handles  => {
        discard_add     => 'push',
        discards    => 'elements',
        discard_count    => 'count',
        discard_get      => 'get',
    },
);
1;
