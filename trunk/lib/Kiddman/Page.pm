package Kiddman::Page;
use Moose;
use Kiddman::Meta::Attribute::Trait::Labeled;

use MooseX::Types
    -declare => [qw(
        LongStr
    )];

use MooseX::Types::Moose 'Str';

subtype LongStr, as Str;

has meta_description => (
    traits => [qw(Labeled)],
    is => 'rw',
    isa => 'LongStr',
    label => "Meta Description"
);
has template => (
    traits => [qw(Labeled)],
    is => 'rw',
    isa => 'Str',
    default => sub { 'page.tt' },
    label => 'Template'
);
has title => (
    traits => [qw(Labeled)],
    is => 'rw',
    isa => 'Str',
    required => 1,
    label => "Title"
);

1;
