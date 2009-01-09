package Kiddman::Controller::Revision;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Kiddman::Controller::Revision - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 item_base

Chain link to load a specific site.

=cut
sub item_base : Chained('/') PathPart('revision') CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    my $rev = $c->model('RW')->resultset('Revision')->find($id);

    unless(defined($rev)) {
        $c->stash->{message} = $c->localize('Unknown Revision.');
        $c->detach('/util/not_found');
    }

    $c->stash->{context}->{revision} = $rev;
}

=head2 show

Show a specific revision.

=cut

sub show : Chained('item_base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

	$c->stash->{template} = 'revision/show.tt';
}



=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
