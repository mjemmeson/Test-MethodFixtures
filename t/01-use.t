use Test::More;

use strict;
use warnings;

BEGIN {

    use_ok $_ foreach qw/
        Test::MethodFixtures
        Test::MethodFixtures::Storage
        Test::MethodFixtures::Storage::File
        /;
}

done_testing();

