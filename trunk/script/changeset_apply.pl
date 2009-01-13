#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use DateTime;
use Getopt::Long;
use Kiddman;

my ($csid, $ignore_date, $ignore_active, $help);
GetOptions(
    'changeset=i' => \$csid,
    'ignore-date' => \$ignore_date,
    'ignore-active' => \$ignore_active,
    'help' => \$help
);
usage() if $help;

my $now = DateTime->now;

if(!defined($csid)) {
    die('Must supply a ChangeSet id');
}

my $schema = Kiddman->model('RW')->schema;

my $cs = $schema->resultset('ChangeSet')->find($csid);

unless(defined($cs)) {
    die('ChangeSet id '.$csid.' not found!');
}

if($cs->applied) {
    die('ChangeSet id '.$csid.' already applied.');
}

if(!$ignore_active && !$cs->active) {
    die('ChangeSet id '.$csid.' is not active, refusing to apply.');
}

if(!$ignore_date && !(defined($cs->date_to_publish) && ($now > $cs->date_to_publish))) {
    die('ChangeSet id '.$csid.' is not ready to be published, refusing to apply.');
}

#$cs->apply;

sub usage {
    print "\nApplies a changeset.\n";
    print "\t--changeset=id\tChangeset to Apply\n";
    print "\t--ignore-date\tIgnore the date, apply even if it's not time.\n";
    print "\t--ignore-active\tIgnore active flag, apply even if inactive.\n";
    exit;
}

1;

