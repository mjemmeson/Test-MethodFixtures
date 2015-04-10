use strict;
use warnings;

use Test::More;
use Test::MethodFixtures;

$ENV{TEST_MF_MODE} = 'record';

ok my $mocker = Test::MethodFixtures->new(), "got mocker";
is $mocker->mode, 'record', 'testing TEST_MF_MODE environment variable';

done_testing();

