use strict;
use lib 't/lib';

use Test::More;

use KiddmanTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Needs DBD::SQLite for testing') : ( tests => 8);
}

my $schema = KiddmanTest->init_schema();
ok($schema, 'Got a schema');

my $site = $schema->resultset('Site')->find(
    { name => 'Test Site', { key => 'sites_name'} }
);
my $page = $schema->resultset('Page')->find(
    { site => $site, site => $site, name => 'Test Page', { key => 'pages_name'} }
);


my $entry1 = $site->add_to_urls({
    user_id => 'gphat',
    path => 'test/entry',
    page => $page,
    description => 'Description'
});
cmp_ok($entry1->file, 'eq', 'entry', 'URL->file');

my $entry2 = $site->add_to_urls({
    user_id => 'gphat',
    path => 'foo/bar/baz',
    page => $page,
    description => 'Description'
});

my $entry3 = $site->add_to_urls({
    user_id => 'gphat',
    path => 'woah/boy',
    page => $page,
    description => 'Description'
});

my $entry4 = $site->add_to_urls({
    user_id => 'gphat',
    path => 'foo/wooptie',
    page => $page,
    description => 'Description'
});

my $entry5 = $site->add_to_urls({
    user_id => 'gphat',
    path => 'foo/bar',
    page => $page,
    description => 'Description'
});

my $ref = $site->get_url_arrayref();

cmp_ok($ref->[0]->[0]->name, 'eq', 'foo', 'foo as directory');
cmp_ok($ref->[0]->[0]->is_leaf, '==', 0, 'directory is not leaf');

cmp_ok($ref->[0]->[1]->[0]->file, 'eq', 'bar', 'bar as URL entry');
cmp_ok($ref->[0]->[1]->[1]->is_leaf, '==', '0', 'bar as directory');

cmp_ok($ref->[0]->[1]->[2]->[0]->file, 'eq', 'baz', 'baz as URL entry');
cmp_ok($ref->[0]->[1]->[2]->[0]->is_leaf, '==', 1, 'URL is leaf');