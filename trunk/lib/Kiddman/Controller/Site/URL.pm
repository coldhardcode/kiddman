package Kiddman::Controller::Site::URL;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Kiddman::Controller::Site::URL - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub site_base : Chained('/site/item_base') PathPart('url') CaptureArgs(0) {
	my ($self, $c) = @_;
}

sub item_base : Chained('/site/item_base') PathPart('url') CaptureArgs(1) {
	my ($self, $c, $id) = @_;

    my $url = $c->model('RW')->resultset('URL')->find($id);

    unless(defined($url)) {
        $c->stash->{message} = 'Unknown URL.';
        $c->detach('/util/not_found');
    }

    $c->stash->{context}->{url} = $url;
}

sub add : Chained('site_base') PathPart('add') Args(0) {
    my ($self, $c) = @_;

    my @pages = $c->model('RW')->resultset('Page')->search({
        active => 1
    })->all;

    $c->stash->{pages} = \@pages;

    $c->stash->{template} = 'site/url/add.tt';
}

sub edit : Chained('item_base') PathPart('edit') Args(0) {
    my ($self, $c) = @_;

    my @pages = $c->model('RW')->resultset('Page')->search({
        active => 1
    })->all;
    $c->stash->{pages} = \@pages;

    $c->stash->{template} = 'site/url/edit.tt';
}

sub show : Chained('item_base') PathPart('show') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template} = 'site/url/show.tt';
}

sub create : Chained('site_base') PathPart('create') Args(0) {
    my ($self, $c) = @_;

    my $url = $c->model('RW')->resultset('URL')->new({
        page_id => $c->req->param('page'),
        site_id => $c->stash->{context}->{site}->id,
        options => $c->req->param('options') || undef,
        description => $c->req->param('description') || undef,
        active => 0,
        path => $c->req->param('path') || undef,
        user_id => 'gphat'
    });

    $c->form(required => [qw(page path description)]);
    unless($c->form_is_valid) {
        $c->stash->{message}->{fail} = $c->localize('Please correct the highlighted errors.');
        $c->detach('add');
    }

    my $rev = $url->make_new;

    unless(defined($rev)) {
        $c->stash->{message}->{fail} = $c->localize('Failed to create URL and Revision.');
        $c->detach('add');
    }

    $c->stash->{message}->{success} = $c->localize('URL [_1] added successfully.', $url->id);
    $c->response->redirect($c->action_uri('Site::URL', 'show', [ $url->id ]), 301);
}

sub save : Chained('site_base') PathPart('save') Args(0) {
    my ($self, $c) = @_;

    my $rev = $c->model('RW')->resultset('Revision')->new({
        url_id => $c->stash->{context}->{url}->id,
        user_id => 'gphat',
        active => 1,
        applied => 0,
        options => $c->req->param('options') || undef,
    });

    $c->form(required => [qw(page path description)]);
    unless($c->form_is_valid) {
        $c->stash->{message}->{fail} = $c->localize('Please correct the highlighted errors');
        $c->detach('add');
    }

    $rev->insert;
    $c->stash->{message}->{success} = $c->localize('Revision [_1] added successfully.', $rev->id);
    $c->response->redirect($c->action_uri('Site::URL', 'show', [ $rev->id ]), 301);
}

=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
