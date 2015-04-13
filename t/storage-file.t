use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;

my $pkg = 'Test::MethodFixtures::Storage::File';

eval "require $pkg";

plan skip_all => "Can't use $pkg" if $@;

BEGIN {

    package MyObject;

    sub new {
        my $class = shift;
        bless { foo => 10 }, $class;
    }
}

my @tests = (
        {   name => 'simple scalar',
            key  => sub {1}
        },
        {   name => 'arrayref',
            key  => sub {
                [ 1, 2 ];
            }
        },
        {   name => 'hashref',
            key  => sub {
                { foo => 'bar' };
            }
        },
        {   name => 'nested',
            key  => sub {
                [ 1, 2, { foo => 'bar', more => [qw/ a b c /] } ];
            },
        },
        {   name => 'object',
            key  => sub {
                [   1, 2,
                    {   foo    => 'bar',
                        more   => [qw/ a b c /],
                        object => MyObject->new(),
                    },
                    MyObject->new(),
                ];
            },
        },
);

# check that filenames are consistent and independent of memory references
subtest key => sub {
        my %seen;
        foreach my $test (@tests) {
            note $test->{name};
            ok my $filename = $pkg->filename( $test->{key}->() ),
                "got filename";
            is $filename, $pkg->filename( $test->{key}->() ),
                "filename consistent";

            ok !$seen{$filename}++, "filename unique";
        }
};

ok my $storage = $pkg->new(), "new $pkg";

subtest store => sub {

        foreach my $test (@tests) {

            ok $storage->store(
                {   method => 'Foo::Bar::thing',
                    key    => $test->{key},
                    input  => 100,
                    output => 200
                }
                ),
                "store()";

        }
};

subtest retrieve => sub {
        foreach my $test (@tests) {

            ok my $stored = $storage->retrieve(
                {   method => 'Foo::Bar::thing',
                    key    => $test->{key},
                }
                ),
                "retrieve()";

            is_deeply $stored, { input => 100, output => 200 }, "data ok";
        }

        dies_ok {
            $storage->retrieve(
                { method => 'Foo::Bar::thing', key => [ 1, 2 ] } )
        }, "dies with key not found";

        dies_ok {
            $storage->retrieve(
                {   method => 'Foo::Bar::another::thing',
                    key    => $tests[0]->{key}
                }
                )
        }, "dies with valid key but wrong class";

};

done_testing();

