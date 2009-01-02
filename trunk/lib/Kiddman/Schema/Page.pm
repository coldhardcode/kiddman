package Kiddman::Schema::Page;
use strict;
use warnings;

use base 'DBIx::Class';

use overload '""' => sub { $_[0]->name }, fallback => 1;

__PACKAGE__->load_components('TimeStamp', 'PK::Auto', 'InflateColumn::DateTime', 'Core');
__PACKAGE__->table('pages');
__PACKAGE__->add_columns(
    id  => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        is_auto_increment => 1,
    },
    site_id => {
        data_type => 'INTEGER',
        is_nullable => 0,
        size => undef,
        is_foreign_key => 1
    },
    class => {
        data_type   => 'VARCHAR',
        is_nullable => 0,
        size        => 255
    },
    name => {
        data_type => 'VARCHAR',
        is_nullable => 0,
        size => 64
    },
    active => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        default_value => 1
    },
    date_created => {
        data_type   => 'DATETIME',
        is_nullable => 0,
        size        => undef,
        set_on_create => 1
    }
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(
    'pages_site_class' => [ qw/site_id class/ ],
);
__PACKAGE__->add_unique_constraint(
    'pages_name' => [ qw/name/ ],
);

__PACKAGE__->belongs_to('site' => 'Kiddman::Schema::Site', 'site_id');

1;