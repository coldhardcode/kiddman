package Kiddman::Schema::Site;
use strict;
use warnings;

use Kiddman::Directory;

use File::Path;
use File::Spec;
use Tree::Simple;
use Tree::Simple::Visitor::ToNestedArray;

use overload '""' => sub { $_[0]->name() }, fallback => 1;

use base 'DBIx::Class';

=head1 NAME

Kiddman::Schema::Site - A Site managed by Kiddman

=head1 SYNOPSIS

    XXX Add a synopsis

=head1 DESCRIPTION

Sites are collections of URLs that are managed by Kiddman.

=cut

__PACKAGE__->load_components('TimeStamp', 'PK::Auto', 'InflateColumn::DateTime', 'Core');
__PACKAGE__->table('sites');
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
    },
    ttl => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef
    },
    active => {
        data_type   => 'INTEGER',
        is_nullable => 0,
        size        => undef,
        default_value => 1
    },
    date_created => {
        data_type   => 'DATETIME',
        is_nullable => 0,
        size        => undef,
        set_on_create => 1
    }
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint(
    'sites_name' => [ qw/name/ ],
);

__PACKAGE__->has_many('urls' => 'Kiddman::Schema::URL', 'site_id');

=head1 METHODS

=over 4

=item B<active>

Active flag.

=item B<apply_changeset>

Apply the supplied changeset to this Site.

The ChangeSet will iterate over it's Revisions, applying each one.  If a 
revision has already been applied then it will be skipped.  That shouldn't
really happen.

Returns the number of applied Revisions.

=cut
sub apply_changeset {
	my ($self, $changeset) = @_;

    my $revs = $changeset->revisions;

    my $count = 0;
    while(my $rev = $revs->next) {
        if($rev->applied) {
            next;
        }
        $rev->apply;
        $count++;
    }
    return $count;
}

=item B<date_created>

Date this site was created.

=item B<get_url_arrayref>

Returns an arrayref, wherein the 'directory structure' of the urls is
represented as an arrayref.

=cut
sub get_url_arrayref {
    my $self = shift;

    my $tree = $self->get_url_tree;

    my $visitor = Tree::Simple::Visitor::ToNestedArray->new;
    $visitor->includeTrunk(0);
    $tree->accept($visitor);
    my $array = $visitor->getResults;

    return $array;
}

=item B<get_url_tree>

Returns an Tree::Simple object, wherein the 'directory structure' of the urls is
represented with leaf nodes as L<Kiddman::Schema::Page> objects and non-leaf nodes
are L<Kiddman::Directory> objects.

=cut
sub get_url_tree {
    my $self = shift;

    my $urls = $self->urls->active->search(undef, { order_by => 'path' });

    my $tree = new Tree::Simple($self, Tree::Simple->ROOT);

    while(my $url = $urls->next()) {

        my $name = $url->path;

        if($name =~ /\//) {
            my ($vol, $dir, $file) = File::Spec->splitpath($name);
            my $node = $self->_find_or_create_nodes($tree, $dir);
            $node->addChild(new Tree::Simple($url));
        } else {
            $tree->addChild(new Tree::Simple($url));
        }
    }

    $self->{'nodes'} = undef;

    return $tree;
}

=item B<id>

Id of this site.

=item B<name>

Name of this site.

=item B<ttl>

Time to live (in seconds) for this site.  Used by actual site implementation
for caching.

=cut

sub _find_or_create_nodes {
	my ($self, $tree, $path) = @_;

    my @parts = split(/\//, $path);

    my $accum;
    my $node = $tree;
    # Split the path up into pieces and look for nodes.  Since we are taking
    # willy-nilly paths in no particular order, we have to check each piece
    # and see if we've already created a node.  If we have, we'll use it.  If
    # we haven't then create a new one.  We cache the nodes as we create them
    # in $self->{'nodes'}.
    foreach my $p (@parts) {

        next if $p eq '';

        $accum .= "$p/";
        my $fnode = $self->{'nodes'}->{$accum};
        if($fnode) {
            $node = $fnode;
        } else {
            my $nnode = new Tree::Simple(
                Kiddman::Directory->new(name => $p, owner => 'Admin')
            );
            $self->{'nodes'}->{$accum} = $nnode;
            $node->addChild($nnode);
            $node = $nnode;
        }
    }

    return $node;
}

=back

=head1 SEE ALSO

L<Kiddman::Controller::URL>

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;