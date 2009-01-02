package Kiddman::Schema::ChangeSet;
use strict;
use warnings;

use base 'DBIx::Class';

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
    # site_id => {
    #     data_type   => 'INTEGER',
    #     is_nullable => 0,
    #     size        => undef,
    #     is_foreign_key  => 1
    # },
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

=item apply

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

=item revision_count

I hate wantarray.

=cut
sub revision_count {
    my ($self) = @_;

    return $self->revisions->count;
}

package Kiddman::ResultSet::ChangeSet;

use base 'DBIx::Class::ResultSet';

=head1 RESULTSET METHODS

=head2 active

=cut

sub pending {
    my ($self) = @_;

    return $self->search({ applied => 0 });
}

1;