#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Pod::Usage;
use Getopt::Long;

use Kiddman;

my ( $help, $deploy, $ddl, $drop_tables ) = ( 0, 1, 0, 1 );

GetOptions(
    'help|?'   => \$help,
    'deploy|d' => \$deploy,
    'ddl'      => \$ddl,
    'drop'     => \$drop_tables,
);

pod2usage(1) if $help;

my $schema = Kiddman->model('RW')->schema;

if ( $ddl ) {
    $schema->create_ddl_dir(
        [ 'SQLite', 'MySQL' ],
        $Kiddman::VERSION,
        Kiddman->path_to('sql')
    );
}
elsif ( $deploy ) {
    $schema->deploy({ add_drop_table => $drop_tables });

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

} else {
    pod2usage(1);
}

1;

