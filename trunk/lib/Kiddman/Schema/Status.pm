package Kiddman::Schema::Status;
use strict;
use warnings;

use overload '""' => sub { $_[0]->name() }, fallback => 1;

use base 'DBIx::Class';

__PACKAGE__->load_components('PK::Auto', 'Core');
__PACKAGE__->table('statuses');
__PACKAGE__->add_columns(
    id  => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        is_auto_increment => 1,
    },
    name => {
        data_type   => 'VARCHAR',
        is_nullable => 0,
        size        => 255
    }
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint(
    'statuses_name' => [ qw/name/ ],
);

__PACKAGE__->has_many('revisions' => 'Kiddman::Schema::Revision', 'op_id');

1;