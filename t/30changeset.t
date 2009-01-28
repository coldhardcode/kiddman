use strict;
use lib 't/lib';

use DateTime;
use Test::More;

use KiddmanTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Needs DBD::SQLite for testing') : ( tests => 5);
}

my $schema = KiddmanTest->init_schema();
ok($schema, 'Got a schema');

my $site = $schema->resultset('Site')->find({
    name => 'Test Site', { key => 'sites_name'}
});
my $page = $schema->resultset('Page')->find({
    site => $site, name => 'Test Page', { key => 'pages_name'}
});

my $op = $schema->resultset('Op')->find(
    'Change', { key => 'ops_name' }
);

my $url = $schema->resultset('URL')->create({
    user_id => 'test',
    site => $site,
    page => $page,
    path => '/foo/bar',
    options => {
        foo => 'bar'
    },
    description => 'Description',
    active => 1
});
my $options = { bar => 'baz' };
my $rev = $url->revise($op, 'gphat', $options);

my $url2 = $schema->resultset('URL')->create({
    user_id => 'test',
    site => $site,
    page => $page,
    path => '/foo/bar2',
    options => {
        foo => 'bar'
    },
    description => 'Description',
    active => 1
});
my $options2 = { bar => 'baz' };
my $rev2 = $url2->revise($op, 'gphat', $options2);

my $changeset = $schema->resultset('ChangeSet')->create({
    applied => 0,
    comment => 'Test Comment',
    date_to_publish => DateTime->now,
});
isa_ok($changeset, 'Kiddman::Schema::ChangeSet');

$rev->update({ changeset => $changeset });
$rev2->update({ changeset => $changeset });
cmp_ok($changeset->revision_count, '==', 2, '2 revisions');

$changeset->apply;

$url->discard_changes;
$url2->discard_changes;

cmp_ok($url->options->{bar}, 'eq', 'baz', 'url1 changed');
cmp_ok($url2->options->{bar}, 'eq', 'baz', 'url2 changed');