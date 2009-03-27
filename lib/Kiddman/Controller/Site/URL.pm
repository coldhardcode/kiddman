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

sub add : Chained('site_base') PathPart('add') Args(0) {
    my ($self, $c) = @_;

    my @pages = $c->model('RW')->resultset('Page')->search({
        active => 1
    })->all;

    $c->stash->{pages} = \@pages;

    $c->stash->{template} = 'site/url/add.tt';
}

sub create : Chained('site_base') PathPart('create') Args(0) {
    my ($self, $c) = @_;

    my $url = $c->model('RW')->resultset('URL')->new({
        page_id => $c->req->params->{'page'},
        site_id => $c->stash->{context}->{site}->id,
        options => $c->req->params->{'options'} || undef,
        description => $c->req->params->{'description'} || undef,
        active => 0,
        path => $c->req->params->{'path'} || undef,
        user_id => 'gphat'
    });
    $c->stash->{url} = $url;

    my $required = [qw(page path description)];

    my $page = $c->model('RW::Page')->find($c->req->params->{page});
    unless(defined($page)) {
        $c->stash->{message}->{error} = $c->localize('Unknown Page.');
        $c->detach('add');
    }

    # XXX Eval protection!
    # eval {
        Class::MOP::load_class($page->class);
        my @attrs = $page->class->meta->get_all_attributes;
        $c->stash->{meta} = $page->class->meta;

        my $class = Class::MOP::Class->create($page->class."::Proxy");
        foreach my $attr (@attrs) {
            if($attr->is_required) {
                push(@{ $required }, 'options.'.$attr->name);
            }
            $class->add_attribute($attr->name => ( is => 'rw', reader => $attr->name, writer => $attr->name ));
        }
        # $c->stash->{instance} = $page->class->new($url->options);
        $c->stash->{instance} = $class->new_object($url->options);
        $c->form(required => $required);
    # };

    if((defined($@) && ($@ ne '')) || !$c->form_is_valid) {
        my $error = $@;
        if(defined($error)) {
            $c->stash->{message}->{error} = $c->localize('Error: "[_1]"', $error);
        } else {
            $c->stash->{message}->{error} = $c->localize('Please correct the highlighted errors.');
        }
        $c->detach('add');
    }

    my $rev = $url->make_new;

    unless(defined($rev)) {
        $c->stash->{message}->{error} = $c->localize('Failed to create URL and Revision.');
        $c->detach('add');
    }

    $c->stash->{message}->{success} = $c->localize('URL [_1] added successfully.', $url->id);
    $c->response->redirect($c->action_uri('Site::URL', 'show', [ $url->id ]), 303);
	$c->response->body('Redirect');
}

sub edit : Chained('item_base') PathPart('edit') Args(0) {
    my ($self, $c) = @_;

    my $url = $c->stash->{context}->{url};
    $url->revise_for_user('gphat');

    my $revcount = $c->model('RW')->resultset('Revision')->pending->for_user('gphat')->for_url($url)->by_date->count;
    if($revcount) {
        $c->stash->{message}->{'warning'} = $c->loc('Current view is affected by [_1] uncommitted changes.', $revcount);
    }
    $c->stash->{revcount} = $revcount;

    # XXX Nead some eval protection here
    Class::MOP::load_class($url->page->class);
    my $instance = $url->page->class->new($url->options);

    $c->stash->{instance} = $instance;
    $c->stash->{meta} = $instance->meta;

    $c->stash->{template} = 'site/url/edit.tt';
}

sub item_base : Chained('/site/item_base') PathPart('url') CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    my $url = $c->model('RW')->resultset('URL')->find($id);

    unless(defined($url)) {
        $c->stash->{message} = $c->loc('Unknown URL.');
        $c->detach('/util/not_found');
    }

    $c->stash->{context}->{url} = $url;
}

sub save : Chained('item_base') PathPart('save') Args(0) {
    my ($self, $c) = @_;

    my $url = $c->stash->{context}->{url};
    my $act = defined($c->req->params->{active}) ? 1 : 0;
    my $opts = $c->req->params->{options} || undef;

    #XXX Validation
    $c->form(required => [qw(description)]);
    unless($c->form_is_valid) {
        $c->stash->{message}->{error} = $c->localize('Please correct the highlighted errors');
        $c->detach('add');
    }

    my $revs = $url->revise('gphat', $act, $opts);

    if(scalar(@{ $revs })) {
        $c->stash->{message}->{success} = $c->localize('Revision(s) added successfully.', scalar(@{ $revs }));
    } else {
        $c->stash->{message}->{warning} = $c->localize('No Revisions added.');
    }
    $c->response->redirect($c->action_uri('Site::URL', 'show', [ $url->site_id, $url->id ]), 303);
    $c->response->body('Redirect');
}

sub show : Chained('item_base') PathPart('show') Args(0) {
    my ($self, $c) = @_;

    my $url = $c->stash->{context}->{url};

    my $revcount = $c->model('RW')->resultset('Revision')->pending->for_user('gphat')->for_url($url)->by_date->count;
    if($revcount) {
        $c->stash->{message}->{'warning'} = $c->loc('You have [_1] uncommitted changes for this URL.', $revcount);
        # Pass a production version of this URL to the controller.
        $c->stash->{original_url} = $c->model('RW')->resultset('URL')->find($url->id);
    }

    # XXX Nead some eval protection here
    Class::MOP::load_class($url->page->class);
    my $instance = $url->page->class->new($url->options);

    $c->stash->{instance} = $instance;
    $c->stash->{meta} = $instance->meta;

    $c->stash->{template} = 'site/url/show.tt';
}

sub site_base : Chained('/site/item_base') PathPart('url') CaptureArgs(0) {
    my ($self, $c) = @_;
}

=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
