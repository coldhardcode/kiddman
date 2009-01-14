package Kiddman::Controller::ChangeSet;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Kiddman::Controller::ChangeSet - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 add

=cut

sub add : Local {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'changeset/add.tt';

    my $onrevs = $c->req->params->{'url'};
    if(!defined($onrevs) || (ref($onrevs) ne 'HASH')) {
        $c->stash->{message}->{error} = $c->loc('No URLs provided.');
        return;
    }

    my @urls;
    foreach my $url (keys(%{ $c->req->params->{'url'} })) {
        $url =~ s/^U//;
        push(@urls, $url);
    }

    unless(scalar(@urls)) {
        $c->stash->{message}->{error} = $c->loc('No URLs provided.');
        return;
    }

    my $urlrs = $c->model('RW')->resultset('URL')->search({
        'me.id' => { '-in' => \@urls }
    });
    $c->stash->{urls} = [ $urlrs->pending_url_revisions_by_user('gphat')->all ];
}

=head2 apply

=cut

sub apply : Chained('item_base') PathPart('apply') Args(0) {
    my ($self, $c) = @_;

    my $cs = $c->stash->{context}->{changeset};
    $cs->publisher_id('gphat');
    $cs->date_to_publish($c->req->params->{apply_date});
    $cs->update;

    $c->stash->{message}->{'success'} = $c->loc('ChangeSet scheduled for application');
    $c->response->redirect($c->uri_for('/'), 303);
	$c->response->body('Redirect');
}

=head2 confirm

=cut
sub confirm : Chained('item_base') PathPart('confirm') Args(0) {
    my ($self, $c, $id) = @_;

    $c->stash->{template} = 'changeset/confirm.tt';
}

=head2 create

=cut
sub create : Local {
    my ($self, $c) = @_;

    my $onrevs = $c->req->params->{'url'};
    if(!defined($onrevs) || (ref($onrevs) ne 'HASH')) {
        $c->stash->{message}->{error} = $c->loc('No URLs provided.');
        return;
    }

    my @urls;
    foreach my $url (keys(%{ $c->req->params->{'url'} })) {
        $url =~ s/^U//;
        push(@urls, $url);
    }

    unless(scalar(@urls)) {
        $c->stash->{message}->{error} = $c->loc('No URLs provided.');
        return;
    }

    my $schema = $c->model('RW')->schema;

    my $status = $schema->resultset('Status')->find('Pending', {
        key => 'statuses_name'
    });

    my $url_rs = $c->model('RW')->resultset('URL');

    my $changeset;
    my $makechange = sub {
        $changeset = $schema->resultset('ChangeSet')->create({
            applied => 0,
            comment => $c->req->params->{'comment'}
        });

        foreach my $url (@urls) {
            my $u = $url_rs->find($url);

            my $revrs = $schema->resultset('Revision')->pending_for_user_for_url('gphat', $u);
            my @revids = $revrs->get_column('me.id')->all;
            $schema->resultset('Revision')->search({
                id => { '-in' => \@revids}
            })->update({
                changeset_id => $changeset->id,
                status_id => $status->id
            });
        }
    };

    eval {
        $schema->txn_do($makechange);
    };
    if($@) {
        $c->stash->{message}->{error} = $c->localize('Error creating ChangeSet: '.$@);
        $c->detach('add');
    }


    $c->stash->{message}->{success} = $c->localize('ChangeSet [_1] created successfully.', $changeset->id);
    $c->response->redirect($c->uri_for('/'), 303);
	$c->response->body('Redirect');
}

=head2 item_base

Chain link to load a specific site.

=cut
sub item_base : Chained('/') PathPart('changeset') CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    my $change = $c->model('RW')->resultset('ChangeSet')->find($id);

    unless(defined($change)) {
        $c->stash->{message} = $c->localize('Unknown ChangeSet.');
        $c->detach('/util/not_found');
    }

    $c->stash->{context}->{changeset} = $change;
}

=head2 show

=cut
sub show : Chained('item_base') PathPart('') Args(0) {
    my ($self, $c, $id) = @_;

    if($c->stash->{context}->{changeset}->is_stale) {
        $c->stash->{message}->{warning} = $c->loc('This ChangeSet is stale.');
    }

    $c->stash->{template} = 'changeset/show.tt';
}

=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
