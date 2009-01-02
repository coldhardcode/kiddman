package Kiddman::Meta::Attribute::Trait::Labeled;
use Moose::Role;

has label => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_label'
);

1;