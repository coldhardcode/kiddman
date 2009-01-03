package #
    Foo::Bar;
use Moose;

use MooseX::Types
    -declare => [qw(
        Baz
    )];

use Color;

use MooseX::Types::Moose qw(Str);

subtype Baz,
    as 'Color',
    where { defined($_) && ref($_) && $_->isa('Color') };

coerce Baz,
    from Str,
    via { Color->new(name => $_) };

1;