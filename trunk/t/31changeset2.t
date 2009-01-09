use strict;
use lib 't/lib';

use Test::More;

use KiddmanTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Needs DBD::SQLite for testing') : ( tests => 13);
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
    version => 1,
    description => 'Description'
});

my $op = $schema->resultset('Op')->find('Change', { key => 'ops_name' });

my $options2 = { bar => 'baz' };
my $rev = $url->revise($op, 'gphat', $options2);
ok(defined($rev), 'got a revision');
isa_ok($rev, 'Kiddman::Schema::Revision');

my $rev2 = $url->revise($op, 'gphat', $options2);
cmp_ok($rev->id, '==', $rev2->id, 'didnt dupe rev');

cmp_ok($rev->options->{'bar'}, 'eq', 'baz', 'revision options');

my $changeset = $schema->resultset('ChangeSet')->create({
    applied => 0,
    comment => 'Test Comment',
});

$rev->update({ changeset => $changeset });
$rev2->update({ changeset => $changeset });

my $nochanges = $schema->resultset('ChangeSet')->pending;
cmp_ok($nochanges->count, '==', 0, '0 pending changeset');

$changeset->update({ date_to_publish => DateTime->now });

my $changes = $schema->resultset('ChangeSet')->pending;
cmp_ok($changes->count, '==', 1, '1 pending changeset');

$changeset->apply;

$changeset->discard_changes;
cmp_ok($changeset->applied, '==', 1, 'applied flag set');
ok(defined($changeset->date_published), 'date_published set');
cmp_ok($changeset->publisher_id, 'eq', 'SYSTEM', 'SYSTEM user ');

$url->discard_changes;
cmp_ok($url->options->{'bar'}, 'eq', 'baz', 'url changed');
cmp_ok($url->version, '==', $rev->id, 'url version set');

my $donechanges = $schema->resultset('ChangeSet')->pending;
cmp_ok($donechanges->count, '==', 0, '0 pending changesets');
