use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Kiddman' }
BEGIN { use_ok 'Kiddman::Controller::ChangeSet' }

ok( request('/changeset')->is_success, 'Request should succeed' );


