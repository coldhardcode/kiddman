package #
    TestProvider;
use Moose;

with 'Kiddman::TypeProvider';

use Color;

sub get_values {
    my ($self) = @_;

    my $things = ( UCString->new('one'), UCString->new('two') );
}

1;