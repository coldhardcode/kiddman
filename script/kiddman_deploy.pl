#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Pod::Usage;
use Getopt::Long;

use Kiddman;

my ( $help, $deploy, $ddl, $drop_tables, $populate ) = ( 0, 1, 0, 1, 0 );

GetOptions(
    'help|?'   => \$help,
    'deploy|d' => \$deploy,
    'ddl'      => \$ddl,
    'drop'     => \$drop_tables,
    'populate' => \$populate,
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
    my $options = { 
        add_drop_table => $drop_tables,
        import => { 
            'Op'        => 'data/operations.csv', 
            'Status'    => 'data/status.csv',
        },
    };

    if ( $populate ) {
        $options->{import} = {
            'Op'        => 'data/operations.csv',
            'Status'    => 'data/status.csv',
            'Site'      => 'data/sites.csv', 
            'Page'      => 'data/pages.csv', 
            'URL'       => 'data/urls.csv', 
        };
    }
    $schema->deploy($options);
} else {
    pod2usage(1);
}

1;

