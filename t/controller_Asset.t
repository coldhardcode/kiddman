use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Kiddman' }
BEGIN { use_ok 'Kiddman::Controller::Asset' }

ok( request('/asset')->is_success, 'Request should succeed' );


