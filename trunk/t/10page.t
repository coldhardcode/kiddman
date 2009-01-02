use strict;
use lib 't/lib';

use Test::More;
use YAML::XS;

use KiddmanTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'Needs DBD::SQLite for testing') : ( tests => 4);
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
	description => 'Description'
});

ok(!defined($url->options), 'No options.');

my $options = {
	foo => [qw(1 2 3)],
	bar => {
		baz => 1
	}
};
$url->options($options);
$url->update;
ok(defined($url->options), 'Has options.');
cmp_ok($url->get_column('options'), 'eq', Dump($options), 'get_column eq YAML');