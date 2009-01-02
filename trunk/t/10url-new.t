use strict;
use lib 't/lib';

use Test::More;

use KiddmanTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Needs DBD::SQLite for testing') : ( tests => 6);
}

my $schema = KiddmanTest->init_schema;
ok($schema, 'Got a schema');

my $site = $schema->resultset('Site')->find({
	name => 'Test Site', { key => 'sites_name'}
});
my $page = $schema->resultset('Page')->find({
    site => $site, name => 'Test Page', { key => 'pages_name'}
});

my $url = $schema->resultset('URL')->new({
    user_id => 'test',
    site => $site,
    page => $page,
    path => '/foo/bar',
    options => {
        foo => 'bar'
    },
    description => 'Description'
});

my $rev = $url->make_new;
isa_ok($rev, 'Kiddman::Schema::Revision');
$url->discard_changes;
cmp_ok($url->active, '==', 0, 'new url is inactive');
cmp_ok($rev->status->name, 'eq', 'In Progress', 'revision is in progress');
cmp_ok($rev->op->name, 'eq', 'Activate', 'revision is an activate');

$rev->apply;
$url->discard_changes;
cmp_ok($url->active, '==', 1, 'URL is active (activate op)');

