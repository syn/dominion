package Dominion::Interaction;

use strict;
use warnings;
use Moose;

has 'type'      => ( isa => 'Str', is => 'ro', required => 1 );


1;