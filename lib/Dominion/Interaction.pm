package Dominion::Interaction;

use Moose;

my $interaction_id = 0;

has 'id'       => ( is => 'ro', isa => 'Int', default => sub { $interaction_id++ } );
has 'resolved' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'player'   => ( is => 'rw', isa => 'Dominion::Player' );
has 'card'     => ( is => 'rw', isa => 'Dominion::Card' );
has 'callback' => ( is => 'rw', isa => 'CodeRef' );
has 'message'  => ( is => 'rw', isa => 'Str' ,default => '');


sub done {
    my ($self) = @_;

    $self->callback->($self) if $self->callback;
    $self->resolved(1);
}

#__PACKAGE__->meta->make_immutable;
1;
