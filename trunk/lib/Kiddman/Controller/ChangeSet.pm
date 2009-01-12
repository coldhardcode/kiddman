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

    my $onrevs = $c->req->params->{'revision'};
    if(!defined($onrevs) || (ref($onrevs) ne 'HASH')) {
        $c->stash->{message}->{error} = 'No revisions provided.';
        return;
    }

    my @revs;
    foreach my $rev (keys(%{ $c->req->params->{'revision'} })) {
        $rev =~ s/^R//;
        push(@revs, $rev);
    }

    unless(scalar(@revs)) {
        $c->stash->{message}->{error} = 'No revisions provided.';
        return;
    }

    my $revrs = $c->model('RW')->resultset('Revision')->active->pending->for_user('gphat')->search({
        'me.id' => { '-in' => \@revs }
    });
    $c->stash->{revisions} = [ $revrs->all ];
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

    my $onrevs = $c->req->params->{'revision'};
    if(!defined($onrevs) || (ref($onrevs) ne 'HASH')) {
        $c->stash->{message}->{error} = 'No revisions provided.';
        return;
    }

    my @revs;
    foreach my $rev (keys(%{ $c->req->params->{'revision'} })) {
        $rev =~ s/^R//;
        push(@revs, $rev);
    }

    unless(scalar(@revs)) {
        $c->stash->{message}->{error} = 'No revisions provided.';
        return;
    }

    my $schema = $c->model('RW')->schema;

    my $status = $schema->resultset('Status')->find('Pending', {
        key => 'statuses_name'
    });

    my $changeset;
    my $makechange = sub {
        $changeset = $schema->resultset('ChangeSet')->create({
            applied => 0,
            comment => $c->req->params->{'comment'}
        });

        $schema->resultset('Revision')->search({
            'me.id' => { '-in' => \@revs }
        })->update({
            changeset_id => $changeset->id,
            status_id => $status->id
        })
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

    $c->stash->{template} = 'changeset/show.tt';
}

=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
