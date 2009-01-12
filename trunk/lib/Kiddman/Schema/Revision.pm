package Kiddman::Schema::Revision;
use strict;
use warnings;

use base 'DBIx::Class';

use YAML::XS;

=head1 NAME

Kiddman::Schema::Revision - Revision to a URL.

=head1 SYNOPSIS

    my $revision = $url->revise($op, $user, $options);

=head1 DESCRIPTION

Revisions are changes to URLs in Kiddman.

=cut

__PACKAGE__->load_components('TimeStamp', 'PK::Auto', 'InflateColumn::DateTime', 'Core');
__PACKAGE__->table('revisions');
__PACKAGE__->resultset_class('Kiddman::ResultSet::Revision');
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

=head1 METHODS

=over 4

=item B<active>

Active flag.

=head2 apply([ $url ])

Apply this Revision to it's URL.  If the Revision is not active or it's
status is 'Applied' it will not apply.  Sets the status to applied. Returns a
1 for success, 0 for failure.

B<NOTE:> If you pass in a URL then this method WILL NOT COMMIT CHANGES MADE.
Passing in a URL means you want to manage the URL yourself.  You will need to
call C<update> on B<both> this revision and the URL.

If the version number of the URL does not match the version of this revision
then this method will die.

=cut
sub apply {
    my ($self, $url) = @_;

    unless($self->active) {
        return 0;
    }

    # If no URL was passed in then fetch it.  This means we aren't in test
    # mode.
    my $test = 1;
    unless(defined($url)) {
        $url = $self->url;
        $test = 0;
    }

    # In test mode we'll allow any ol' revision to be applied
    if(!$test && ($self->status->name ne 'Pending')) {
        return 0;
    }

    my $schema = $self->result_source->schema;
    my $appstatus = $schema->resultset('Status')->find(
        'Applied', { key => 'statuses_name' }
    );

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
    if($op->name eq 'Change') {

        $url->options($self->options);
        $url->version($self->id);
    } elsif($op->name eq 'Activate') {
        if($url->active) {
            die('URL already active.');
        }
        $url->active(1);
    } elsif($op->name eq 'Deactivate') {
        if(!$url->active) {
            die('URL already inactive.');
        }
        $url->active(0);
    }

    if(!$test) {
        my $apply = sub {
            $url->update;
            $self->update({ status => $appstatus });
        };

        eval {
            $schema->txn_do($apply);
        };
        if($@) {
            # Rethrow
            die($@);
        }
    }

    return 1;
}

=item B<changeset>

Changeset this revision belongs to.

=item B<changeset>

ID of Changeset this revision belongs to.

=item B<date_created>

Date this revision was created.

=item B<id>

Id of this revision.

=item B<op>

Type of op this revision represents.

=item B<op>

ID of Type of op this revision represents.

=item B<options>

Options for this revision.  Stored as YAML but automatically inflated and
deflated using L<YAML::XS>.

=item B<status>

Status of this revision.

=item B<status_id>

ID of status of this revision.

=item B<url>

URL this is a revision of.

=item B<url_id>

ID of URL this is a revision of.

=item B<user_id>

User id that created this Revision.

=item B<version>

Version of URL at the time this revision was created.  Protects "old"
revisions from being applied to URLs.

=back

=cut

package Kiddman::ResultSet::Revision;

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

=head2 by_date 

Order the revisions in this resultset by date created.

=cut
sub by_date {
    my ($self) = @_;

    return $self->search(undef, { order_by => \'date_created ASC'});
}

=item B<for_url>

Finds revisions for the given url object.

=cut

sub for_url {
    my ($self, $url) = @_;

    return $self->search({ url_id => $url->id });
}

=item B<for_user>

Finds revisions for the given user_id.

=cut

sub for_user {
    my ($self, $user) = @_;

    return $self->search({ user_id => $user });
}

=item B<op>

Finds revisions for the given op object.

=cut

sub op {
    my ($self, $op) = @_;

    return $self->search({ op_id => $op->id });
}

=item B<pending>

Finds revisions that have not been applied.
    
=cut

sub pending {
    my ($self, $user) = @_;

    return $self->search(
        { 'status.name' => 'In Progress' },
        { join => 'status' }
    );
}

=head2 unapplied

Finds any B<active> revisions that have not been applied.

=cut

sub unapplied {
    my ($self) = @_;

    return $self->search(
        { active => 1, 'status.name' => { '!=' => 'Applied' } },
        { join => 'status' }
    );
}

=back

=head1 SEE ALSO

L<Kiddman::Controller::Page>

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;