use strict;
use lib 't/lib';

use Test::More;

use KiddmanTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Needs DBD::SQLite for testing') : ( tests => 11);
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
    description => 'Description'
});

my $op = $schema->resultset('Op')->find('Change', { key => 'ops_name' });
my $status_pending = $schema->resultset('Status')->find(
    'Pending', { key => 'statuses_name' }
);

my $options2 = { bar => 'baz' };
my $rev = $url->revise($op, 'gphat', $options2);
ok(defined($rev), 'got a revision');
isa_ok($rev, 'Kiddman::Schema::Revision');

my $rev2 = $url->revise($op, 'gphat', $options2);
cmp_ok($rev->id, '==', $rev2->id, 'didnt dupe rev');

cmp_ok($rev->options->{'bar'}, 'eq', 'baz', 'revision options');

my $rev3 = $rev->copy;

my $unaprs = $schema->resultset('Revision')->unapplied;
cmp_ok($unaprs->count, '==', 2, '2 unapplied revisions');

$rev->update({ status => $status_pending });

my $ret = $rev->apply;
cmp_ok($ret, '==', 1, 'revision applied');
$url->discard_changes;
cmp_ok($url->options->{'bar'}, 'eq', 'baz', 'url changed');
cmp_ok($url->version, '==', $rev->id, 'url version set');

cmp_ok($unaprs->count, '==', 1, '1 unapplied revisions');

$rev3->update({ status => $status_pending });

eval {
    $rev3->apply;
};
ok($@ =~ /^Version mismatch: Rev:none/, 'rev3 version mismatch');
