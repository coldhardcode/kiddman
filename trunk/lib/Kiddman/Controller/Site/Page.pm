package Kiddman::Controller::Site::Page;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Kiddman::Controller::Site::Page - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 item_base

=cut

sub item_base : Chained('/site/item_base') PathPart('page') CaptureArgs(1) {
	my ($self, $c, $id) = @_;

	my $page = $c->model('RW::Page')->search({
		site_id => $c->stash->{context}->{site}->id,
		id => $id
	})->single;

    unless(defined($page)) {
        $c->stash->{message} = $c->localize('Unknown Page.');
        $c->detach('/util/not_found');
    }

	$c->stash->{context}->{page} = $page;
}

=head2 attributes

=cut

sub attributes : Chained('item_base') PathPart('attributes') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{page}->{layout} = 'partial';

    my $page = $c->stash->{context}->{page};

    # XXX Nead some eval protection here
    Class::MOP::load_class($page->class);

    $c->stash->{meta} = $page->class->meta;
    $c->stash->{template} = 'site/page/attributes.tt';
}

=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
