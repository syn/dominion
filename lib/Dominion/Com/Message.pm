package Dominion::Com::Message;

use Moose;

has 'type'      => ( isa => 'Str', is => 'ro', required => 1 );

sub is {
    my ($self, $type) = @_;

    return 1 if $self->type eq $type;
    return;
}

1;
