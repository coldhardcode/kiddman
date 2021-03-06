package Kiddman::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Kiddman::Controller::Root - Root Controller for kiddman

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 auto

=cut
sub auto : Private {
    my ($self, $c) = @_;

    my @sites = $c->model('RW')->resultset('Site')->all;
    $c->stash->{sites} = \@sites;
}


=head2 base

Everything starts here, chain-wise.

=cut
sub base : Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub index : Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $schema = $c->model('RW')->schema;

    my $status = $schema->resultset('Status');

    my $urls = $schema->resultset('URL')->pending_url_revisions_by_user('gphat');
    $c->stash->{in_progress_urls} = [ $urls->all ];

    my $cs_rs = $schema->resultset('ChangeSet');

    my $pending = $cs_rs->pending;
    my $scheduled = $cs_rs->scheduled;

    $c->stash->{pending_changesets} = [ $pending->all ];
    $c->stash->{scheduled_changesets} = [ $scheduled->all ];

    $c->stash->{template} = 'default.tt';
}

sub guide : Local {
    my ($self, $c) = @_;

    $c->stash->{template} = 'guide.tt';
}

sub default :Path {
    my ( $self, $c ) = @_;

    $c->response->status(404);
    $c->stash->{template} = '404.tt';
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : Private {
    my ($self, $c) = @_;

    if(defined($c->stash->{view}) && $c->stash->{view} eq 'json') {
        delete($c->stash->{view});
        $c->forward('View::JSON');
	} elsif($c->response->body) {
		$c->detach;
    } else {
        $c->forward('View::TT');
    }
}

=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
