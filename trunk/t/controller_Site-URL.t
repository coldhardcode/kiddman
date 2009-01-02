use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Kiddman' }
BEGIN { use_ok 'Kiddman::Controller::Site::URL' }

ok( request('/site/url')->is_success, 'Request should succeed' );


