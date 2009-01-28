use strict;
use lib 't/lib';

use Test::More;

use KiddmanTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Needs DBD::SQLite for testing') : ( tests => 10);
}

my $schema = KiddmanTest->init_schema();
ok($schema, 'Got a schema');

my $site = $schema->resultset('Site')->find(
    { name => 'Test Site', { key => 'sites_name'} }
);
my $page = $schema->resultset('Page')->find(
    { site => $site, name => 'Test Page', { key => 'pages_name'} }
);


my $url1 = $site->add_to_urls({
    user_id => 'test',
    path => 'test/entry',
    page => $page,
    description => 'Description'
});
cmp_ok($url1->file, 'eq', 'entry', 'URL->file');

my $url2 = $site->add_to_urls({
    user_id => 'test',
    path => 'foo/bar/baz',
    page => $page,
    description => 'Description'
});

my $url3 = $site->add_to_urls({
    user_id => 'test',
    path => 'woah/boy',
    page => $page,
    description => 'Description'
});

my $url4 = $site->add_to_urls({
    user_id => 'test',
    path => 'foo/wooptie',
    page => $page,
    description => 'Description'
});

my $url5 = $site->add_to_urls({
    user_id => 'test',
    path => 'foo/bar',
    page => $page,
    description => 'Description'
});

my $tree = $site->get_url_tree();

cmp_ok($tree->getChild(0)->getNodeValue->name, 'eq', 'foo', 'foo as directory');
cmp_ok($tree->getChild(0)->isLeaf, '==', 0, 'directory is not leaf');
cmp_ok($tree->getChild(0)->getChildCount, '==', 3, 'foo has 3 children');
cmp_ok(
	$tree->getChild(0)->getChild(0)->getNodeValue->path,
	'eq', 'foo/bar', 'bar as URL entry'
);
cmp_ok($tree->getChild(0)->getChild(1)->getNodeValue->name, 'eq', 'bar', 'bar as directory');
cmp_ok($tree->getChild(0)->getChild(1)->isLeaf, '!=', 1, 'bar is not leaf');
cmp_ok($tree->getChild(2)->getNodeValue->name, 'eq', 'woah', 'woah as directory');
cmp_ok($tree->getChild(2)->isLeaf, '!=', 1, 'woah is not leaf');