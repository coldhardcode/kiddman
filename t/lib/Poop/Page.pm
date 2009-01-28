package Poop::Page;
use Moose;

use Foo::Bar;

extends 'Kiddman::Page';

has 'color' => (
    is => 'rw',
    isa => 'Foo::Bar::Baz',
    coerce => 1
);

1;