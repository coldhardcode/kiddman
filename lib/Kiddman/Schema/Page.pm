package Kiddman::Schema::Page;
use strict;
use warnings;

use base 'DBIx::Class';

use overload '""' => sub { $_[0]->name }, fallback => 1;

=head1 NAME

Kiddman::Schema::Page - Page

=head1 SYNOPSIS

    my $page = $c->model('Page')->create({
        site_id => 1,
        class => 'Some::Class',
        name => 'Some Class',
        active => 0,
    });

=head1 DESCRIPTION

Pages are records in Kiddman's database that correspond to classes in the
Kiddman managed application that extend L<Kiddman::Page>.

=cut

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

=head1 METHODS

=head2 active

Active flag.

=head2 class

Class name that implements this page.

=head2 date_created

Date this page was created.

=head2 id

Page id.

=head2 name

Name of page.

=head2 site

Site this page belongs to.

=head2 site_id

ID of site this page belongs to.

=head1 SEE ALSO

L<Kiddman::Controller::Revision>

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;