package Kiddman::Types;
use Moose;

use MooseX::Types
    -declare => [qw(
        LongStr
    )];

use MooseX::Types::Moose 'Str';

subtype LongStr, as Str;

1;