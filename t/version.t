use strict;
use warnings;

use Test::More;
use Test::MethodFixtures;

my $pkg = 'Test::MethodFixtures::Storage::File';

eval "require $pkg";

plan skip_all => "Can't use $pkg" if $@;

BEGIN {

    package Mocked::NoVersion;

    our $expensive_call = 0;

    sub foo {
        $expensive_call++;
        my $arg = $_[0] || 0;
        return $arg + 5;
    }

    package Mocked::Version;

    our $VERSION = "2";
    our $expensive_call = 0;

    sub foo {
        $expensive_call++;
        my $arg = $_[0] || 0;
        return $arg + 5;
    }
}

my ( $result, $stderr );

ok my $mocker = Test::MethodFixtures->new(), "got mocker";

ok $mocker->mock('Mocked::NoVersion::foo'), "mocked simple sub";

ok $mocker->mode('record'), "set mode to record";

is Mocked::NoVersion::foo(), 5, "call mocked function";

ok $mocker->mode('playback'), "set mode to playback";

eval { require Capture::Tiny };
SKIP: {
        skip "Can't use Capture::Tiny", 4;

        $stderr
            = Capture::Tiny::capture_stderr { $result = Mocked::NoVersion::foo() };
        is $result, 5,  "function result ok";
        is $stderr, '', "stderr ok";

        $Test::MethodFixtures::VERSION = '0.00002';

        $stderr
            = Capture::Tiny::capture_stderr { $result = Mocked::NoVersion::foo() };
        is $result, 5, "function result ok";
        like $stderr,
            qr{Data saved with a more recent version \([\d.]+\) of Test::MethodFixtures!},
            "stderr ok";
}

done_testing();

