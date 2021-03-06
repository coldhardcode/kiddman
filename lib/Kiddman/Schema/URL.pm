package Kiddman::Schema::URL;
use strict;
use warnings;

use base 'DBIx::Class';

use File::Spec;
use Test::Deep::NoTest;
use YAML::XS;

use overload '""' => sub { $_[0]->file }, fallback => 1;

=head1 NAME

Kiddman::Schema::URL - A URL managed by Kiddman

=head1 SYNOPSIS

    XXX Add a synopsis

=head1 DESCRIPTION

URLs correspond to paths in the managed site.

=cut

__PACKAGE__->load_components('TimeStamp', 'PK::Auto', 'InflateColumn::DateTime', 'Core');
__PACKAGE__->table('urls');
__PACKAGE__->resultset_class('Kiddman::ResultSet::URL');
__PACKAGE__->add_columns(
    id  => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        is_auto_increment => 1,
    },
    site_id => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        is_foreign_key => 1,
    },
    page_id => {
        data_type	=> 'INTEGER',
        is_nullable => 0,
        size        => undef,
        is_foreign_key => 1
    },
    user_id => {
        data_type   => 'VARCHAR',
        is_nullable => 0,
        size        => '64',
    },
    version => {
        data_type	=> 'INTEGER',
        size        => undef,
        is_nullable => 1,
        default     => 0
    },
    options => {
        data_type	=> 'TEXT',
        is_nullable => 1,
    },
    description => {
        data_type	=> 'VARCHAR',
        size => 255,
        is_nullable => 0
    },
    path => {
        data_type   => 'VARCHAR',
        size        => 255,
        is_nullable => 0
    },
    active => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        default_value => 1
    },
    date_last_modified => {
        data_type   => 'DATETIME',
        is_nullable => 0,
        size        => undef,
        set_on_create => 1,
        set_on_update => 1
    },
    date_created => {
        data_type   => 'DATETIME',
        is_nullable => 0,
        size        => undef,
        set_on_create => 1
    }
);

__PACKAGE__->inflate_column('options', {
    inflate => sub { Load(shift()) },
    deflate => sub { Dump(shift()) },
});

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(
    'entries_site_id_path' => [ qw/site_id path/ ],
);

__PACKAGE__->belongs_to('site' => 'Kiddman::Schema::Site', 'site_id');
__PACKAGE__->belongs_to('page' => 'Kiddman::Schema::Page', 'page_id');
__PACKAGE__->has_many('revisions' => 'Kiddman::Schema::Revision', 'url_id');

=head1 METHODS

=over 4

=head2 active

Active flag.

=head2 date_created

Date this URL was created.

=head2 date_last_modified

Date this URL was last modified.

=head2 description

Description of this URL.

=head2 file

Returns the final "element" in the path, which I am haphazardly referring to as the
'file' portion.  A path of '/foo/bar/baz' will return 'baz'.

=cut
sub file {
    my ($self) = @_;

    my @parts = split('\/', $self->path);
    return $parts[$#parts];
}

=head2 id

Id of URL.

=head2 is_leaf

Provided to make working with the L<Site|Kiddman::Site>'s C<get_entry_arrayref>
easier, as nodes can be tested for leaf status.  Returns true.

=cut
sub is_leaf {
    return 1;
}

=head2 make_new

Convenience method that creates a new URL and an accompanying 'Pending'
Revision that is in 'In Progress', all inside of a transaction.  Returns
the revision on success, undef on failure.

=cut

sub make_new {
    my ($self) = @_;

    my $schema = $self->result_source->schema;

    my $op = $schema->resultset('Op')->find(
        'Activate', { key => 'ops_name' }
    );
    my $status = $schema->resultset('Status')->find(
        'In Progress', { key => 'statuses_name' }
    );

    # New URLs can't be active, as that would skip the workflow
    $self->active(0);

    my $pagemaker = sub {
        $self->insert;
        my $rev = $schema->resultset('Revision')->create({
            url_id => $self->id,
            op_id => $op->id,
            status_id => $status->id,
            user_id => 'gphat',
            active => 1,
        });
        return $rev;
    };

    my $rev;
    eval {
        $rev = $schema->txn_do($pagemaker);
    };
    if($@) {
        return undef;
    }

    return $rev;
}

=head2 options

Options for this revision.  Stored as YAML but automatically inflated and
deflated using L<YAML::XS>.

=heda2 page

Page this used at this URL.

=head2 page_id

Id of Page this used at this URL.

=head2 path

Path of this URL.

=head2 revise($user, $options)

Creates a revision from this URL or modifies any extant unapplied revisions by this user
to have the specified options.  The new Revision will have a version number
that matches the current version of the this URL.  See C<Revision>'s C<apply>
method for more details.  Returns an arrayref of revisions... one for each created
by this method.

=cut
sub revise {
    my ($self, $user, $active, $options) = @_;

    my $schema = $self->result_source->schema;

    $self->revise_for_user($user);

    # Any newly created revisions will need this...
    my $status = $schema->resultset('Status')->find(
        'In Progress', { key => 'statuses_name' }
    );
    my $revrs = $schema->resultset('Revision');
    my @revisions;

    # Check if the active flag is involved.
    if($active != $self->active) {
        my $op;
        if($active) {
            # They want to active an inactive page
            $op = $schema->resultset('Op')->find('Activate', { key => 'ops_name' });
        } else {
            # They want to deactive an active page, create a revision for it
            $op = $schema->resultset('Op')->find('Deactivate', { key => 'ops_name' });
        }

        my $rev = $schema->resultset('Revision')->create({
            url_id => $self->id,
            op_id => $op->id,
            status_id => $status->id,
            user_id => $user,
            active => 1,
            version => $self->version
        });
        push(@revisions, $rev);
    }

    # Check the options and create a revision if they don't match.
    unless(eq_deeply($options, $self->options)) {

        my $op = $schema->resultset('Op')->find('Change', { key => 'ops_name' });
        my $rev = $schema->resultset('Revision')->create({
            url_id => $self->id,
            op_id => $op->id,
            status_id => $status->id,
            user_id => $user,
            options => $options,
            active => 1,
            version => $self->version
        });
        push(@revisions, $rev);
    }

    return \@revisions;
}

=head2 revise_for_user($user_id)

Applies any active, unapplied revisions to the URL and returns the result but
B<does not commit the result>.  You shouldn't commit it either, as the
revisions applied would not be marked as such.

=cut

sub revise_for_user {
    my ($self, $user_id) = @_;

    # XXX Use MX::Method::Signatures, need to validate the user_id

    my $revrs = $self->result_source->schema->resultset('Revision');
    $revrs = $revrs->pending->for_user($user_id)->for_url($self)->by_date;

    while(my $rev = $revrs->next) {
        $rev->apply($self); # Apply in test mode
    }
}

=head2 site

Site this URL belongs to.

=head2 site_id

Id of Site this URL belongs to.

=head2 user

User that created this URL.

=head2 user_id

Id of User that created this URL.

=head2 version

Version of this URL.  The version is the id of the last revision applied to
the URL.  This protects from applying revisions that were created from older
URLs.

=back

=cut

package Kiddman::ResultSet::URL;

use base 'DBIx::Class::ResultSet';

=head1 RESULTSET METHODS

=head2 active

Finds active revisions.

=cut

sub active {
    my ($self) = @_;

    return $self->search({ active => 1 });
}

=head2 for_path

Find 

=cut

sub for_path {
    my ($self, $path) = @_;

    return $self->search({ path => $path });
}

=head2 for_site

Find URLS for the given site.

=cut

sub for_site {
    my ($self, $site) = @_;

    return $self->search({ site_id => $site->id });
}

=head2 pending_url_revisions_by_user

Returns all the URLs this user has with pending revisions, plus an extra column
(retrieved with get_column) named 'rev_count' that counts the total number of
revisions pending for the given URL.

=cut

sub pending_url_revisions_by_user {
    my ($self, $userid) = @_;

    return $self->search(
        {
            'status.name' => 'In Progress',
            'revisions.active' => 1,
            'me.user_id' => $userid
        }, {
            join => { 'revisions' => 'status' },
            group_by => 'me.id',
            '+select' => [ \'COUNT(*) AS rev_count' ],
            '+as' => 'rev_count'
        }
    );
}

=head1 SEE ALSO

L<Kiddman::Controller::Site>

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;