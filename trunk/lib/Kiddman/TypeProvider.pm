package Kiddman::TypeProvider;
use Moose::Role;

use Template;

has 'input_type' => (
    is => 'rw',
    isa => ''
);

requires 'get_values';

1;