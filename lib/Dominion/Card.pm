package Dominion::Card;

use Moose;

sub name        { die 'Name is required (' . ref(shift) . ')' }
sub tags        { qw() }
sub box         { die 'Box is required (' . ref(shift) . ')' }
sub cost_coin   { die 'Coin cost is required (' . ref(shift) . ')' }
sub cost_potion { die 'Potion cost is required (' . ref(shift) . ')' }


has 'in_set' => ( isa => 'Dominion::Set', is => 'rw', trigger => \&remove_from_current_set );
has 'count'     => ( isa => 'Int', is => 'rw', default => 1);

sub is {
    my ($self, $tag) = @_;

    return scalar grep { $tag eq $_ } $self->tags;
}

sub remove_from_current_set {
    my ($self, $new, $old) = @_;

    return unless $old;

    my $index = $old->find_index($self);

    return unless defined $index;

    $old->delete($index);
}

sub TO_JSON {
	my ($self) = @_;
	return {
		name => $self->name,
		image => lc($self->name) .".jpg",
		available => $self->count,
	};
}

=head2 coin

How much coin does this card give you by being in your hand? (Note that this
isn't the place for cards that give you more coin when you play them).

=cut
sub coin { 0 }

#__PACKAGE__->meta->make_immutable;
1;
