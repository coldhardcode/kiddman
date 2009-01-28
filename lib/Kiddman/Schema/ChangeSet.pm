package Kiddman::Schema::ChangeSet;
use strict;
use warnings;

use base 'DBIx::Class';

use DateTime;

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
    active => {
        data_type => 'TINYINT',
        is_nullable => 0,
        size => 1,
        default => 1
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
        is_nullable => 1,
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

__PACKAGE__->has_many('revisions' => 'Kiddman::Schema::Revision', 'changeset_id');

=head2 applied

Applied flag.

=head2 apply

Applies all the Revisions in this ChangeSet.  If any of the Revisions fail to
apply then this method will die (and all changes will be rolled back).  Returns
if there are no Revisions (which would be stupid).

Revisions are applied in reverse order, oldest first.  Inactive Revisions are
skipped.

=cut
sub apply {
    my ($self, $userid) = @_;

    $userid = 'SYSTEM' unless defined($userid);

    my $count = $self->revision_count;
    return if $count < 1;

    my $app = sub {
        my $revs = $self->revisions->active->by_date;
        while(my $rev = $revs->next) {
            $rev->apply;
        }
        $self->update({
            applied => 1,
            date_published => DateTime->now,
            publisher_id => $userid
        });
    };

    my $schema = $self->result_source->schema;
    eval {
        $schema->txn_do($app);
    };
    if($@) {
        die $@;
    }
}

=head2 comment

Comment by the creator of this changeset.

=head2 date_created

Date this changeset was created.

=head2 date_published

Date this changeset was published (applied).

=head2 date_to_publish

The date this changeset is to be applied.  Used for delaying publishing.

=head2 id

This changesets's id.

=head2 is_stale

Returns true if B<any> of the revisions in this changeset are stale.

=cut

sub is_stale {
    my ($self) = @_;

    my $revs = $self->revisions;
    while(my $rev = $revs->next) {
        if($rev->is_stale) {
            return 1;
        }
    }

    return 0;
}

=head2 publisher_id

User that published this changeset.

=head2 revision_count

Returns the number of revisions in this changeset. I hate wantarray.

=cut
sub revision_count {
    my ($self) = @_;

    return $self->revisions->count;
}

=head2 revisions_ordered_by_site

Convenience method primarily provided for using with TT, since wantarray is the
devil.  Returns this ChangeSet's revisions ordered by Site.

=cut

sub revisions_ordered_by_site {
    my ($self) = @_;

    return $self->revisions->search(
        { 'me.active' => 1 },
        { join => 'url', order_by => 'url.site_id' }
    );
}

=head2 revisions

Returns the revisions in this ChangeSet

=cut

package Kiddman::ResultSet::ChangeSet;

use base 'DBIx::Class::ResultSet';

=back

=head1 RESULTSET METHODS

=head2 active

Returns all active ChangeSets

=cut

sub active {
    my ($self) = @_;

    return $self->search({ active => 1 });
}

=head2 scheduled

Returns all unapplied ChangeSets that do not have a date_to_publish set.

=cut

sub scheduled {
    my ($self) = @_;

    return $self->active->search({ date_to_publish => \'IS NOT NULL', applied => 0 });
}

=head2 pending

Returns all unapplied ChangeSets that do not have a date_to_publish set.

=cut

sub pending {
    my ($self) = @_;

    return $self->search({ date_to_publish => \'IS NULL', applied => 0 });
}

=head1 SEE ALSO

L<Kiddman::Schema::Revision>

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;