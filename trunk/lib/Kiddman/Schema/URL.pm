package Kiddman::Schema::URL;
use strict;
use warnings;

use base 'DBIx::Class';

use File::Spec;
use YAML::XS;

use overload '""' => sub { $_[0]->file }, fallback => 1;

__PACKAGE__->load_components('TimeStamp', 'PK::Auto', 'InflateColumn::DateTime', 'Core');
__PACKAGE__->table('urls');
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

=item B<file>

Returns the final "element" in the path, which I am haphazardly referring to as the
'file' portion.  A path of '/foo/bar/baz' will return 'baz'.

=cut
sub file {
    my ($self) = @_;

    my @parts = split('\/', $self->path);
    return $parts[$#parts];
}

=item B<is_leaf>

Provided to make working with the L<Site|Kiddman::Site>'s C<get_entry_arrayref>
easier, as nodes can be tested for leaf status.  Returns true.

=cut
sub is_leaf {
    return 1;
}

=item B<make_new>

Convenience method that creates a new page and an accompanying 'Pending'
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
1;