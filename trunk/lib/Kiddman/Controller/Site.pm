package Kiddman::Controller::Site;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Kiddman::Controller::Site - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 base

=cut

#sub base : Chained('.') PathPart('') CaptureArgs(0) { }

=head2 add

Add a site.

=cut

sub add : Local {
	my ($self, $c) = @_;

	$c->stash->{template} = 'site/add.tt';
}

sub create : Local {
	my ($self, $c) = @_;

	my $site = $c->model('RW')->resultset('Site')->new({
		name => $c->req->params->{'name'} || undef,
		active => $c->req->params->{'active'} ? 1 : 0
	});

	$c->form(required => [qw(name)]);
	unless($c->form_is_valid) {
		$c->stash->{message}->{fail} = $c->localize('Please correct the highlighted errors');
		$c->detach('add');
	}

	$site->insert;
	$c->stash->{message}->{success} = $c->localize('Site [_1] added successfully.', $site->id);
	$c->response->redirect($c->action_uri('Site', 'show', [ $site->id ]), 303);
	$c->response->body('Redirect');
}

=item B<fetch_url>

Retrieve a url for the current site with the given path.

=cut

sub fetch_url : Chained('item_base') PathPart('fetch_url') Args(0) {
    my ($self, $c) = @_;

    my $path = $c->req->params->{'path'};
    my $site = $c->stash->{context}->{site};

    my $url = $c->model('RW')->resultset('URL')->for_site($site)->active->for_path($path)->first;

    unless(defined($url)) {
        $c->log->warn('No URL for site '.$site->id.', path '.$path);
        $c->stash->{message} = $c->localize('Unknown URL.');
        $c->detach('/util/not_found');
    }

    delete($c->stash->{context});# = undef;
    delete($c->stash->{sites});

    $c->stash->{view} = 'json';
    $c->stash->{page} = $url->page->class;
    $c->stash->{options} = $url->options;
}

=head2 item_base

Chain link to load a specific site.

=cut
sub item_base : Chained('/') PathPart('site') CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    my $site = $c->model('RW')->resultset('Site')->find($id);

    unless(defined($site)) {
        $c->stash->{message} = $c->localize('Unknown Site.');
        $c->detach('/util/not_found');
    }

    $c->stash->{context}->{site} = $site;
}

sub show : Chained('item_base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template} = 'site/show.tt';
}

sub edit : Chained('item_base') PathPart('edit') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template} = 'site/edit.tt';
}

=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
