package Kiddman::Schema::ChangeSet;
use strict;
use warnings;

use base 'DBIx::Class';

=head1 NAME

Kiddman::Schema::ChangeSet - Set of Revisions (changes)

=head1 SYNOPSIS

    my $changeset = $c->model('ChangeSet')->create({
        applied => 0,
        comment => 'My Changes!',
    });
    $changeset->add_to_revisions(...);
    $changeset->apply;

=head1 DESCRIPTION

ChangeSets are collections of revisions that a user has chosen to group
together for application to a Site (or Sites).

=head1 METHODS

=over 4

=cut

__PACKAGE__->load_components('TimeStamp', 'PK::Auto', 'InflateColumn::DateTime', 'Core');
__PACKAGE__->table('changesets');
__PACKAGE__->resultset_class('Kiddman::ResultSet::ChangeSet');
__PACKAGE__->add_columns(
    id  => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        is_auto_increment => 1,
    },
    applied => {
        data_type => 'TINYINT',
        is_nullable => 0,
        size => 1,
        default => 0
    },
    comment => {
        data_type   => 'TEXT',
        is_nullable => 0,
        size        => undef
    },
    date_to_publish => {
        data_type   => 'DATETIME',
        is_nullable => 0,
        size        => undef
    },
    publisher_id => {
        data_type   => 'VARCHAR',
        is_nullable => 1,
        size        => '64',
    },
    date_published => {
        data_type   => 'DATETIME',
        is_nullable => 1,
        size        => undef,
    },
    date_created => {
        data_type   => 'DATETIME',
        is_nullable => 0,
        size        => undef,
        set_on_create => 1
    }
);
__PACKAGE__->set_primary_key('id');

# __PACKAGE__->belongs_to('site' => 'Kiddman::Schema::Site', 'site_id');
__PACKAGE__->has_many('revisions' => 'Kiddman::Schema::Revision', 'changeset_id');

=item B<applied>

Applied flag.

=item B<apply>

Applies all the Revisions in this ChangeSet.  If any of the Revisions fail to
apply then this method will die (and all changes will be rolled back).  Returns
if there are no Revisions (which would be stupid).

=cut
sub apply {
    my ($self) = @_;

    my $count = $self->revision_count;
    return if $count < 1;

    my $app = sub {
        my $revs = $self->revisions;
        while(my $rev = $revs->next) {
            $rev->apply;
        }
    };

    my $schema = $self->result_source->schema;
    eval {
        $schema->txn_do($app);
    };
}

=item B<comment>

Comment by the creator of this changeset.

item B<date_created>

Date this changeset was created.

=item B<date_published>

Date this changeset was published (applied).

=item B<date_to_publish>

The date this changeset is to be applied.  Used for delaying publishing.

=item B<id>

This changesets's id.

=item B<publisher_id>

User that published this changeset.

=item B<revision_count>

Returns the number of revisions in this changeset. I hate wantarray.

=cut
sub revision_count {
    my ($self) = @_;

    return $self->revisions->count;
}

package Kiddman::ResultSet::ChangeSet;

use base 'DBIx::Class::ResultSet';

=back

=head1 RESULTSET METHODS

=over 4

=item B<pending>

Returns all unapplied ChangeSets.

=cut

sub pending {
    my ($self) = @_;

    return $self->search({ applied => 0 });
}

=back

=head1 SEE ALSO

L<Kiddman::Schema::Revision>

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

1;