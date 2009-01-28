use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Kiddman' }
BEGIN { use_ok 'Kiddman::Controller::Site::Page' }

ok( request('/site/page')->is_success, 'Request should succeed' );


