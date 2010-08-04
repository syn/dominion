package Dominion::Human;

use 5.010;
use Moose;
use List::Util qw(shuffle);
no warnings 'recursion';

extends 'Dominion::AI';

has 'buycount' => ( is => 'rw', isa => 'Int', default => 0 );
has 'controller' => ( is => 'rw', isa => 'Mojolicious::Controller' , default => undef  ); 

sub action {
    my ($self, $player, $state) = @_;
    
    #Send a choice to the player 
	my $choice = Dominion::Com::Messages::Choice->new(message => 'Action phase : actions = ' . $state->{actions} );
	my $option1 = Dominion::Com::Messages::Options::Button->new(event => 'finishactionphase', name=>'Finish Action Phase Early');
	#TODO only send the cards that can be played.
	
	my $option2 = Dominion::Com::Messages::Options::Play->new(event => 'playcard',cards => [$player->hand->cards_of_type('action')]);
	
	$choice->add($option1);
	$choice->add($option2);
	$self->send_to_player($choice,$player);
}

sub buy {
    my ($self, $player, $state) = @_;

    $self->buycount($self->buycount+1);

    my $game = $player->game;
    
    #Send a choice to the player 
	my $choice = Dominion::Com::Messages::Choice->new(message => 'Buy phase : buys = ' . $state->{buys} . ' , gold = ' . $state->{coin});
	my $option1 = Dominion::Com::Messages::Options::Button->new(event => 'finishturn', name=>'Finish Buy Phase Early');
		
	my $option2 = Dominion::Com::Messages::Options::Buy->new(event => 'cardbrought',cards => [map { $_ } grep { $_->cost_coin <= $state->{coin} } $game->supply->cards]);

	$choice->add($option1);
	$choice->add($option2);
	$self->send_to_player($choice,$player);
}

sub send_to_player {
	my ($self,$message, $player) = @_;
	my $json = JSON->new->utf8;
	$self->controller->send_message( $json->convert_blessed->encode($message) );
}

#__PACKAGE__->meta->make_immutable;
1;
