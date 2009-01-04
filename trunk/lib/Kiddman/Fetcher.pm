package Kiddman::Fetcher;
use warnings;
use strict;

use Class::MOP;
use LWP::UserAgent;
use JSON::XS;

sub fetcher {
    my ($url, $siteid, $path) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $resp = $ua->get($url."/site/$siteid/fetch_url?path=/$path");

    if($resp->is_success) {
        my $inst = decode_json($resp->content);

        use Data::Dumper;
        print STDERR Dumper($inst);

        if(defined($inst->{class})) {
            Class::MOP::load_class($inst->{class});
            return $inst->{class}->new($inst->{options});
        }

    } else {
        print STDERR $resp->status_line;
        return undef;
    }
}

1;