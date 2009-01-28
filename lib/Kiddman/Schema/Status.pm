package Kiddman::Schema::Status;
use strict;
use warnings;

use overload '""' => sub { $_[0]->name() }, fallback => 1;

use base 'DBIx::Class';

=head1 NAME

Kiddman::Schema::Status - Revision Statys

=head1 SYNOPSIS

    my $statrs = $c->model('Status')->all;

=head1 DESCRIPTION

Statuses are used to keep the state of a revision.

=cut

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

=head1 METHODS

=head2 id

Status id.

=head2 name

Name of status.

=head2 revisions

Revisions of this status.

=back

=head1 SEE ALSO

L<Kiddman::Controller::Revision>

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;