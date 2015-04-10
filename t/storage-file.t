use strict;
use warnings;

use Test::More;

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

my @filenames;
foreach my $test (@tests) {
        note $test->{name};
        ok my $filename = $pkg->filename( $test->{key}->() ), "got filename";
        is $filename, $pkg->filename( $test->{key}->() ), "filename consistent";

        my @matched = grep { $filename eq $_ } @filenames;
        ok !@matched, "filename unique";

        push @matched, $filename;
}

done_testing();

