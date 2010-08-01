package Dominion::Com::Message;

use Moose;

has 'type'      => ( isa => 'Str', is => 'ro', required => 1 );

sub is {
    my ($self, $type) = @_;

    return 1 if $self->type eq $type;
    return;
}

sub send_to_player {
	my ($self, $player) = @_;
	my $json = JSON->new->utf8;
	$player->controller->send_message( $json->convert_blessed->encode($self) );
}
sub send_to_everyone {
	my ($self, $game) = @_;
	my $json = JSON->new->utf8;
	foreach my $player ( $game->players ) {
		$player->controller->send_message( $json->convert_blessed->encode($self) );
	}
}

sub send_to_everyone_else {
	my ($self, $player) = @_;
	my $json = JSON->new->utf8;
	foreach my $otherplayer ( $player->game->players ) {
		if($player != $otherplayer) {
			$otherplayer->controller->send_message( $json->convert_blessed->encode($self) );
		}
	}
}
1;
