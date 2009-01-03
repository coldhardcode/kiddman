package Kiddman::Types;
use Moose;

use MooseX::Types
    -declare => [qw(
        LongStr
    )];

use MooseX::Types::Moose 'Str';

enum 'Inputs' => qw(text select checkbox);

subtype LongStr, as Str;

1;