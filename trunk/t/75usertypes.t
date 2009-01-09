use strict;
use Test::More tests => 7;

use lib 't/lib';

use Color;
use Poop::Page;
use Kiddman;

my $page = Poop::Page->new(title => 'New Page');
isa_ok($page, 'Poop::Page');

my $tc = $page->meta->get_attribute_map->{color}->type_constraint;

cmp_ok($tc->name, 'eq', 'Foo::Bar::Baz', 'correct type constraint');

$page->color('orange');

isa_ok($page->color, 'Color');
my $newcolor = Color->new(name => 'blue');
ok($tc->check($newcolor), 'check validates color');
ok(!$tc->check($page), 'check invalidates page');

Kiddman->config->{types}->{'Foo::Bar::Baz'} = 'TestProvider';
my $provider = Kiddman->get_provider('Foo::Bar::Baz');
isa_ok($provider, 'TestProvider');

my $types = $provider->get_values(1, 'user_id');
cmp_ok(ref($types), 'eq', 'ARRAY', 'got array of types');
