package #
    KiddmanTest;

use strict;
use warnings;

use Kiddman::Schema;

sub init_schema {
    my $self = shift();

    my $schema = Kiddman::Schema->connect($self->_database());

    $schema->deploy;

    my $site = $schema->resultset('Site')->create({
       name => 'Test Site',
       ttl  => 120,
    });

    my $page = $schema->resultset('Page')->create({
        site => $site,
        name => 'Test Page',
        class => 'TestPage'
    });

    # Ops
    $schema->resultset('Op')->create({
        name => 'Activate',
    });
    $schema->resultset('Op')->create({
        name => 'Deactivate'
    });
    $schema->resultset('Op')->create({
        name => 'Change'
    });

    # Statuses
    $schema->resultset('Status')->create({
        name => 'In Progress'
    });
    $schema->resultset('Status')->create({
        name => 'Pending',
    });
    $schema->resultset('Status')->create({
        name => 'Applied'
    });


    return $schema;
}

sub _database {
    my $self = shift();

    my $db = 't/var/kiddman.db';

    unlink($db) if -e $db;
    unlink($db.'-journal') if -e $db.'-journal';
    mkdir('t/var') unless -d 't/var';

    my $dsn = "dbi:SQLite:$db";

    my @connect = ($dsn, '', '', { AutoCommit => 1});

    return @connect;
}

1;