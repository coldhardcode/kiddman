package Kiddman::Schema::URL;
use strict;
use warnings;

use base 'DBIx::Class';

use File::Spec;
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

=head1 METHODS

=over 4

=item B<active>

Active flag.

=item B<date_created>

Date this URL was created.

=item B<date_last_modified>

Date this URL was last modified.

=item B<description>

Description of this URL.

=item B<file>

Returns the final "element" in the path, which I am haphazardly referring to as the
'file' portion.  A path of '/foo/bar/baz' will return 'baz'.

=cut
sub file {
    my ($self) = @_;

    my @parts = split('\/', $self->path);
    return $parts[$#parts];
}

=item B<id>

Id of URL.

=item B<is_leaf>

Provided to make working with the L<Site|Kiddman::Site>'s C<get_entry_arrayref>
easier, as nodes can be tested for leaf status.  Returns true.

=cut
sub is_leaf {
    return 1;
}

=item B<make_new>

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

=item B<options>

Options for this revision.  Stored as YAML but automatically inflated and
deflated using L<YAML::XS>.

=item B<page>

Page this used at this URL.

=item B<page_id>

Id of Page this used at this URL.

=item B<path>

Path of this URL.

=item B<revise($user, $options)>

Creates a revision from this URL or modifies any extant unapplied revisions by this user
to have the specified options.  The new Revision will have a version number
that matches the current version of the this URL.  See C<Revision>'s C<apply>
method for more details.

=cut
sub revise {
    my ($self, $op, $user, $options) = @_;

    my $schema = $self->result_source->schema;

    my $revrs = $schema->resultset('Revision');

    my $revision = $revrs->op($op)->for_url($self)->for_user($user)->pending->single;

    unless(defined($revision)) {

        my $status = $schema->resultset('Status')->find(
            'In Progress', { key => 'statuses_name' }
        );

        $revision = $schema->resultset('Revision')->create({
            url_id => $self->id,
            op_id => $op->id,
            status_id => $status->id,
            user_id => $user,
            options => $options,
            active => 1,
            version => $self->version
        });
    }

    return $revision;
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
    $revrs = $revrs->unapplied->for_user($user_id)->for_url($self)->by_date;

    while(my $rev = $revrs->next) {
        $rev->apply($self); # Apply in test mode
    }
}


=item B<site>

Site this URL belongs to.

=item B<site_id>

Id of Site this URL belongs to.

=item B<user>

User that created this URL.

=item B<user_id>

Id of User that created this URL.

=item B<version>

Version of this URL.  The version is the id of the last revision applied to
the URL.  This protects from applying revisions that were created from older
URLs.

=back

=cut

package Kiddman::ResultSet::URL;

use base 'DBIx::Class::ResultSet';

=head1 RESULTSET METHODS

=over 4

=item B<active>

Finds active revisions.

=cut

sub active {
    my ($self) = @_;

    return $self->search({ active => 1 });
}

=item B<for_path>

Find 

=cut

sub for_path {
    my ($self, $path) = @_;

    return $self->search({ path => $path });
}

=item B<for_site>

Find URLS for the given site.

=cut

sub for_site {
    my ($self, $site) = @_;

    return $self->search({ site_id => $site->id });
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