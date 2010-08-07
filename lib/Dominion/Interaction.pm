package Dominion::Interaction;

use Moose;

has cause => (isa => 'Str', is => 'rw', required => 1 ); 
has 'player' => (
    is       => 'rw',
    isa      => 'Dominion::Player',
);

has 'options' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Dominion::Interactions]',
    default  => sub { [] },
    handles  => {
        add      => 'push',
        options    => 'elements',
        count    => 'count',
        get      => 'get',
    },
);
1;
