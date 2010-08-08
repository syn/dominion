package Dominion::Com::Messages::Option;

use Moose;
extends 'Dominion::Com::Message';

has '+type'      => default => 'newhand';
has 'event'      => ( isa => 'Str', is => 'rw', required => 1 );  #The event that gets sent back if the client selects this option

1;
