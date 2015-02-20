use strict;
use warnings;

use Test::More;
use Test::Requires 'Capture::Tiny';
use Test::MethodFixtures;

BEGIN {

    package Mocked::Simple;

    our $expensive_call = 0;

    sub foo {
        $expensive_call++;
        my $arg = $_[0] || 0;
        return $arg + 5;
    }
}

my ( $result, $stderr );

ok my $mocker = Test::MethodFixtures->new(), "got mocker";

ok $mocker->mock('Mocked::Simple::foo'), "mocked simple sub";

ok $mocker->mode('record'), "set mode to record";

is Mocked::Simple::foo(), 5, "call mocked function";

ok $mocker->mode('playback'), "set mode to playback";

$stderr = Capture::Tiny::capture_stderr { $result = Mocked::Simple::foo() };
is $result, 5,  "function result ok";
is $stderr, '', "stderr ok";

$Test::MethodFixtures::VERSION = '0.00002';

$stderr = Capture::Tiny::capture_stderr { $result = Mocked::Simple::foo() };
is $result, 5, "function result ok";
like $stderr,
    qr{Data saved with a more recent version \([\d.]+\) of Test::MethodFixtures!},
    "stderr ok";

done_testing();

