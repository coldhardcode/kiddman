package Kiddman::Model::RW;
use strict;

# use Greenspan::Database;

use base qw(Catalyst::Model::DBIC::Schema);

# my $db = Greenspan::Database->new('kiddman');

__PACKAGE__->config(
    schema_class => 'Kiddman::Schema',
    # connect_info => [
    #     $db->dsn(),
    #     $db->user(),
    #     $db->pass(),
    #     $db->options(),
    #     {
    #         'quote_char' => '`',
    #         'name_sep' => '.',
    #         on_connect_do   => [ 'SET @@SQL_AUTO_IS_NULL=0' ]
    #     }
    # ]
);

1;
