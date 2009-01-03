package Kiddman::Schema::Op;
use strict;
use warnings;

use overload '""' => sub { $_[0]->name() }, fallback => 1;

use base 'DBIx::Class';

=head1 NAME

Kiddman::Schema::Op - Revision Ops

=head1 SYNOPSIS

    my $oprs = $c->model('Op')->all;

=head1 DESCRIPTION

Ops are types used to classify (and change the behavior of) Revisions.

=cut

__PACKAGE__->load_components('PK::Auto', 'Core');
__PACKAGE__->table('ops');
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
    'ops_name' => [ qw/name/ ],
);

__PACKAGE__->has_many('revisions' => 'Kiddman::Schema::Revision', 'op_id');

=head1 METHODS

=over 4

=item B<id>

Op id.

=item B<name>

Name of op.

=item B<revisions>

Revisions of this op type.

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