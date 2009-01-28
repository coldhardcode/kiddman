package Kiddman::Schema;
use strict;
use warnings;

use base 'DBIx::Class::Schema';

use Carp;
use Text::xSV;

__PACKAGE__->load_classes;

sub deploy {
    my ( $self, $properties ) = @_;
    
    my $data_import = delete $properties->{import};

    my $key_check_off;
    my $key_check_on;

    if ( $self->storage->connect_info->[0] =~ /^DBI:mysql/i ) {
        $key_check_off = "SET FOREIGN_KEY_CHECKS = 0;";
        $key_check_on  = "SET FOREIGN_KEY_CHECKS = 1;";
    }

    my $populate_txn = sub {
        $self->SUPER::deploy($properties, @_);

        return unless $data_import and ref $data_import eq 'HASH';
        $self->storage->dbh->do($key_check_off) if $key_check_off;

        foreach my $data ( keys %$data_import ) {
            my $rs = $self->resultset($data);
            unless ( $rs ) {
                carp "Unknown result set in import: $data"
            }
            my $csv = Text::xSV->new;
            $csv->open_file($data_import->{$data});
            $csv->read_header;
            foreach my $field ( $csv->get_fields ) {
                if ( lc($field) ne $field ) {
                    $csv->alias($field, lc($field));
                }
            }

            while ( my $row = $csv->fetchrow_hash ) {
                eval { $rs->create($row); };
                if ( $@ ) {
                    die "Unable to insert row from data: " . join(', ', values %$row) . "\n\t$@\n";
                }
            }
        }
        $self->storage->dbh->do($key_check_on) if $key_check_on;
    };
    $self->txn_do( $populate_txn );
    if ( $@ ) {
        die "Unable to deploy and populate data: $@";
    }
}

1;
