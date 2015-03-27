use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MethodFixtures;

use File::Temp qw( tempdir );

BEGIN {

    package Mocked;

    our $expensive_call = 0;

    sub foo {
        $expensive_call++;
        return $_[0] * $_[1];
    }
}

subtest auto => sub {

        my $dir = tempdir( "test-methodfixtures-XXXXX", CLEANUP => 1 );

        ok my $mocker
            = Test::MethodFixtures->new(
            { storage => $dir, mode => 'playback' } ),
            "got mocker";

        ok $mocker->mock('Mocked::foo'), "mocked sub";

        dies_ok { Mocked::foo( 3, 3 ) } "dies if nothing stored";

        ok $mocker->mode('auto'), "set mode to auto";

        is Mocked::foo( 3, 3 ), 9,  "call mocked function";
        is Mocked::foo( 4, 3 ), 12, "call mocked function";
        is Mocked::foo( 0, 3 ), 0,  "call mocked function";

        is $Mocked::expensive_call, 3, "called 3 times";

        is Mocked::foo( 0, 3 ), 0,  "call mocked function";
        is Mocked::foo( 4, 3 ), 12, "call mocked function";
        is Mocked::foo( 3, 3 ), 9,  "call mocked function";

        is $Mocked::expensive_call, 3, "still only called 3 times";

};

done_testing();

