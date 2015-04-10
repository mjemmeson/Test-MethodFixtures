# NAME

Test::MethodFixtures - Convenient mocking of externalities by recording and replaying method calls.

# SYNOPSIS

    use Test::MethodFixtures
        # optionally specify global arguments
        mode    => 'record',
        storage => ...
        ;

    my $mocker = Test::MethodFixtures->new(
        mode => 'record',

        # optionally specify alternative storage

        # override default storage directory
        storage => '/path/to/storage',

        # use alternative Test::MethodFixtures::Storage object
        storage => $storage_obj,

        # load alternative Test::MethodFixtures::Storage:: class
        storage => { 'Alt::Storage::Class' => \%options },
    );

    # simple functions and class methods - can store all arguments
    $mocker->mock("My::Package::Method");

    # object methods - we need to turn $_[0] ($self) into an
    # unique identifier for object, not memory reference
    $mocker->mock( "My::Object::Method",
        sub { $_[0]->firstname . '-' . $_[0]->lastname } );

    # do the same for other arguments
    $mocker->mock(
        "My::Object::Method",
        sub {
            (   $_[0],                                       # use as-is
                $_[1]->firstname . '-' . $_[1]->lastname,    # object in $_[1]
                 # no need to list further arguments if no more changes required
            );
        }
    );

    # skipping arguments that shouldn't be saved - set to undef
    $mocker->mock(
        "My::Package::Method",
        sub {
            (   $_[0],    # keep
                undef,    # discard

                # further args kept as-is
            );
        }
    );

# DESCRIPTION

Record and playback method arguments, for convenient mocking in tests.

Using this module you can replace an expensive, external or non-repeatable call,
so that there is no need to make that call during subsequent testing.

Aims to be low-dependency to minimise disruption with legacy codebases.

# METHODS

## new

    my $mocker = Test::MethodFixtures->new(
        {   mode    => 'record',            # or 'playback'
            storage => '/path/to/storage',  # override default storage directory

            # or use alternative Test::MethodFixtures::Storage object
            storage => $storage_obj,

            # or load alternative Test::MethodFixtures::Storage:: class
            storage => { 'Alt::Storage::Class' => \%options },
        }
    );

Class method. Constructor

## mock

    $mocker->mock("My::Package::method");
    $mocker->mock( "My::Package::method", sub { ( $_[0], ... ) } );

In `record` mode stores the return values of the named method against the
arguments passed through to generate those return values.

In `playback` mode retrieves stored return values of the named method for
the arguments passed in.

The arguments are used to create the key to store the results against.

Optionally takes a second argument of a coderef to manipulate `@_`, for
example to prevent storage of a non-consistent value or to stringify an
object to a unique identifier.
