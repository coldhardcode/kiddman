use strict;
use lib 't/lib';

use Test::More;

use KiddmanTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Needs DBD::SQLite for testing') : ( tests => 15);
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

my $op = $schema->resultset('Op')->find('Change', { key => 'ops_name' });
my $status_pending = $schema->resultset('Status')->find(
    'Pending', { key => 'statuses_name' }
);

my $options2 = { bar => 'baz' };
my $revs = $url->revise('gphat', 1, $options2);
cmp_ok(scalar(@{ $revs }), '==', 1, '1 revision made');
my $rev = $revs->[0];
ok(defined($rev), 'got a revision');
isa_ok($rev, 'Kiddman::Schema::Revision');

my $revs2 = $url->revise('gphat', 1, $options2);
cmp_ok(scalar(@{ $revs2 }), '==', 0, '0 revisions made');

cmp_ok($rev->options->{'bar'}, 'eq', 'baz', 'revision options');

my $rev3 = $rev->copy;

my $unaprs = $schema->resultset('Revision')->unapplied;
cmp_ok($unaprs->count, '==', 2, '2 unapplied revisions');

$rev->update({ status => $status_pending });

ok(!$rev->is_stale, 'revision is not stale (unversioned url)');

my $ret = $rev->apply;
cmp_ok($ret, '==', 1, 'revision applied');
$url->discard_changes;
cmp_ok($url->options->{'bar'}, 'eq', 'baz', 'url changed');
cmp_ok($url->version, '==', $rev->id, 'url version set');

cmp_ok($unaprs->count, '==', 1, '1 unapplied revisions');

$rev3->update({ status => $status_pending });

ok($rev->is_stale, 'original revision now stale');

eval {
    $rev3->apply;
};
ok($@ =~ /^Version mismatch: Rev:none/, 'rev3 version mismatch');

ok(!$rev3->is_stale, 'new revision is not stale');


