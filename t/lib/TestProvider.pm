package #
    TestProvider;
use Moose;

with 'Kiddman::TypeProvider';

use Color;

sub get_values {
    my ($self, $site_id, $user_id) = @_;

    my @things = ( Color->new(name => 'one'), Color->new(name => 'two') );
    return \@things;
}

1;