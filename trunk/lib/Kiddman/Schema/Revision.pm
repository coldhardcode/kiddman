package Kiddman::Schema::Revision;
use strict;
use warnings;

use base 'DBIx::Class';

use YAML::XS;

__PACKAGE__->load_components('TimeStamp', 'PK::Auto', 'InflateColumn::DateTime', 'Core');
__PACKAGE__->table('revisions');
__PACKAGE__->resultset_class('Kiddman::ResultSet::Authorization');
__PACKAGE__->add_columns(
    id  => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        is_auto_increment => 1,
    },
    url_id => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        is_foreign_key => 1
    },
    changeset_id => {
        data_type => 'INTEGER',
        is_nullable => 1,
        size => undef,
        is_foreign_key => 1
    },
    op_id => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        is_foreign_key => 1
    },
    status_id => {
        data_type   => 'INTEGER',
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
    active => {
        data_type => 'TINYINT',
        is_nullable => 0,
        size => 1,
        default => 1
    },
    options => {
        data_type   => 'TEXT',
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

__PACKAGE__->inflate_column('options', {
    inflate => sub { Load(shift()) },
    deflate => sub { Dump(shift()) },
});

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to('changeset' => 'Kiddman::Schema::ChangeSet', 'changeset_id');
__PACKAGE__->belongs_to('op' => 'Kiddman::Schema::Op', 'op_id');
__PACKAGE__->belongs_to('status' => 'Kiddman::Schema::Status', 'status_id');
__PACKAGE__->belongs_to('url' => 'Kiddman::Schema::URL', 'url_id');

=item B<apply>

Apply this Revision to it's Entry.  If the Revision is not active or it's
status is 'Applied' it will not apply.  Sets the status to applied. Returns a
1 for success, 0 for failure.

If the version number of the URL does not match the version of this revision
then this method will die.

=cut
sub apply {
    my $self = shift;

    unless($self->active) {
        return 0;
    }

    my $schema = $self->result_source->schema;
    my $appstatus = $schema->resultset('Status')->find(
        'Applied', { key => 'statuses_name' }
    );

    if($self->status->name eq 'Applied') {
        return 0;
    }

    my $url = $self->url;

    # Version checking.
    if(defined($url->version)) {
        unless(defined($self->version)) {
            die('Version mismatch: Rev:none, URL:'.$url->version);
        }

        if($self->version != $url->version) {
            die('Version mismatch: Rev:'.$self->version.', URL:'.$url->version);
        }
    }

    my $op = $self->op;

    # This is kinda messy here, but this app is pretty simple.  Maybe this
    # will get moved some day.
    my $apply;
    if($op->name eq 'Change') {
        $apply = sub {

            $url->update({
               options => $self->options,
               version => $self->id
            });
            $self->update({ status => $appstatus });
        };
    } elsif($op->name eq 'Activate') {
        if($url->active) {
            die('URL already active.');
        }
        $apply = sub {
            $url->update({
                active => 1
            });
            $self->update({ status => $appstatus });
        };
    } elsif($op->name eq 'Deactivate') {
        if(!$url->active) {
            die('URL already inactive.');
        }
        $apply = sub {
            $url->update({
                active => 0
            });
            $self->update({ status => $appstatus });
        };
    }

    eval {
        $schema->txn_do($apply);
    };
    if($@) {
        # Rethrow
        die($@);
    }

    return 1;
}

package Kiddman::ResultSet::Authorization;

use base 'DBIx::Class::ResultSet';

=head1 RESULTSET METHODS

=head2 active

=cut

sub active {
    my ($self) = @_;

    return $self->search({ active => 1 });
}

=head2 for_url

=cut

sub for_url {
    my ($self, $url) = @_;

    return $self->search({ url_id => $url->id });
}

=head2 for_user

=cut

sub for_user {
    my ($self, $user) = @_;

    return $self->search({ user_id => $user });
}

=head2 op

=cut

sub op {
    my ($self, $op) = @_;

    return $self->search({ op_id => $op->id });
}

=head2 pending {
    
=cut

sub pending {
    my ($self, $user) = @_;

    return $self->search(
        { 'status.name' => 'In Progress' },
        { join => 'status' }
    );
}

1;