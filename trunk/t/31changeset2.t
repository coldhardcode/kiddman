use strict;
use lib 't/lib';

use Test::More;

use KiddmanTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Needs DBD::SQLite for testing') : ( tests => 7);
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
    site_id => $site->id,
    applied => 0,
    comment => 'Test Comment',
    date_to_publish => DateTime->now,
});

$rev->update({ changeset => $changeset });
$rev2->update({ changeset => $changeset });

$changeset->apply;

$url->discard_changes;
cmp_ok($url->options->{'bar'}, 'eq', 'baz', 'url changed');
cmp_ok($url->version, '==', $rev->id, 'url version set');
