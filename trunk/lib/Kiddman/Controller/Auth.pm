package Kiddman::Controller::Auth;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Kiddman::Controller::Auth - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{'template'} = 'auth/index.tt';
}

=head2 login

=cut

sub login : Local {
    my ($self, $c) = @_;

    if($c->authenticate({ username => $c->req->params->{'username'},
                          password => $c->req->params->{'password'} })) {
        $c->detach('/default');
    } else {
        $c->stash->{'error'} = $c->localize('The supplied credentials are incorrect.');
    }

    $c->detach('index');
}

=head1 logout

=cut

sub logout : Local {
    my ($self, $c) = @_;

    $c->logout();

    $c->detach('default');
}

=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
