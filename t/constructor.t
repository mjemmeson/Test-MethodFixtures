use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::MethodFixtures;
use TestMethodFixtures::Dummy;

my $class = 'Test::MethodFixtures';

# sub new {
#     my $class = shift;
#     my %args  = %{ shift() || {} };

#     my $mode    = delete $args{mode}    || $MODE    || 'playback';
#     my $storage = delete $args{storage} || $STORAGE || $DEFAULT_STORAGE;

#     # testing mode
#     $mode = $ENV{TEST_MF_MODE} || $mode;

#     croak "Invalid mode '$MODE'" unless $VALID_MODES{$mode};

#     # storage mechanism
#     $storage = { $storage => {} } unless ref $storage;

subtest with_no_args => sub {
    ok my $obj = $class->new(), "new with no args";
    is $obj->mode, 'playback', 'default mode is playback';
    ok my $storage = $obj->storage, "got storage attribtue";
    isa_ok $storage, 'Test::MethodFixtures::Storage::File';
    is $storage->dir, 't/.methodfixtures', 'default directory ok';
};

subtest with_dir => sub {

    my $new_dir = 't/.methodfixtures/tmp';
    mkdir $new_dir;

    ok my $obj = $class->new( { dir => $new_dir } ),
        "override default directory";
    is $obj->mode, 'playback', 'default mode is playback';
    ok my $storage = $obj->storage, "got storage attribtue";
    isa_ok $storage, 'Test::MethodFixtures::Storage::File';
    is $storage->dir, $new_dir, 'overridden default directory ok';

    END { rmdir $new_dir if -d $new_dir }
};

subtest with_new_class => sub {

        ok my $obj = $class->new( { storage => '+TestMethodFixtures::Dummy' } ),
            "new with storage class";
        is $obj->mode, 'playback', 'default mode is playback';
        ok my $storage = $obj->storage, "got storage attribtue";
        isa_ok $storage, 'TestMethodFixtures::Dummy';

};

subtest with_new_object => sub {
        ok my $obj
            = Test::MethodFixtures->new(
            { storage => TestMethodFixtures::Dummy->new() } ),
            "new with storage object";
        is $obj->mode, 'playback', 'default mode is playback';
        ok my $storage = $obj->storage, "got storage attribtue";
        isa_ok $storage, 'TestMethodFixtures::Dummy';

};

done_testing();

