package Kiddman::TypeProvider;
use Moose::Role;

use Template;

has 'value_accessor' => (
    is => 'ro',
    isa => 'Str',
    default => sub { 'id' }
);

requires 'get_values';

1;