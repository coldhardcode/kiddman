package Kiddman::Controller::Asset;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use JSON::XS;
use LWP::UserAgent;

=head1 NAME

Kiddman::Controller::Asset - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root : Chained('/') PathPart('asset') CaptureArgs(0) {
    my ( $self, $c ) = @_;

}

sub find : Chained('root') PathPart('find') Args(0) {
    my ($self, $c) = @_;

    my $url;
    if(defined($c->req->params->{key})) {
        my $key = $c->req->params->{key};
        $url = $c->config->{Beckley}->{url}."/fetch/key/$key/info";
    } elsif(defined($c->req->params->{uuid})) {
        my $uuid = $c->req->params->{uuid};
        $url = $c->config->{Beckley}->{url}."/fetch/uuid/$uuid/info";
    } else {
        $c->stash->{message}->{error} = $c->loc('Must specify a key or UUID!');
        $c->detach('main');
    }

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $resp = $ua->get($url);

    if($resp->is_success) {
        $c->stash->{asset} = JSON::XS->new->utf8->decode(
            $resp->decoded_content
        );
        if($c->stash->{asset}->{mime_type} =~ /^image/) {
            $c->stash->{image} = 1;
        }
    } else {
        print STDERR $resp->status_line;
    }
}

sub main : Chained('root') PathPart('') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{template} = 'asset/main.tt';
}


=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
