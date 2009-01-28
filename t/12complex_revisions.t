use strict;
use lib 't/lib';

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

$url->discard_changes;

my $revs1 = $url->revise('gphat', 0, $url->options);
cmp_ok(scalar(@{ $revs1 }), '==', 1, '1 revision made');

my $revs2 = $url->revise('gphat', 1, { foo => 'baz' });
cmp_ok(scalar(@{ $revs2 }), '==', 2, '2 revisions made');

$url->discard_changes;
$url->revise_for_user('gphat');
cmp_ok($url->active, '==', 1, 'active');
cmp_ok($url->options->{foo}, 'eq', 'baz', 'options');
