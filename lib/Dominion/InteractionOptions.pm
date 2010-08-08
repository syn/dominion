package Dominion::InteractionOptions;

use Moose;
use Dominion::Player;

has 'cause' => (isa => 'Str', is => 'rw', required => 1 ); 
has 'card'       => ( isa => 'Dominion::Card', is => 'rw' , required => 1);
has 'resolveCallback' => ( is => 'rw', isa => 'CodeRef');

has 'player' => (
    is       => 'rw',
    isa      => 'Dominion::Player',
);


has 'turnstate' => (
    is => 'rw',
    isa => 'Str',
    default => 'waiting',
    required => 1,
);

has 'options' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Interaction]',
    default  => sub { [] },
    handles  => {
        add      => 'push',
        options    => 'elements',
        count    => 'count',
        get      => 'get',
    },
);

1;
