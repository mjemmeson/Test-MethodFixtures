# NAME

Test::MethodFixtures - Convenient mocking of externalities by recording and replaying method calls.

# SYNOPSIS

Setting up mocked methods in a test script:

    # my-test-script.t
    ...
    use Test::MethodFixtures;

    Test::MethodFixtures->new->mock("Their::Package::Method");

    use My::Package;    # has dependency on Their::Package::Method

    ... # unit tests for My::Package here

Example workflow using the mocked methods:

    $> TEST_MF_MODE=record prove -l my-test-script.t
    $> git add t/.methodfixtures
    $> git commit -m 'methodfixtures for my-test-script.t'

    $> prove -l my-test-script.t   # uses saved data

More configuration options:

    use Test::MethodFixtures
        # optionally specify global arguments
        mode    => 'record',
        storage => ...
        ;

    my $mocker = Test::MethodFixtures->new(
        mode => 'record',    # set locally for this object

        # optionally specify alternative storage

        # override default storage directory
        storage => '/path/to/storage',

        # use alternative Test::MethodFixtures::Storage object
        storage => $storage_obj,

        # load alternative Test::MethodFixtures::Storage:: class
        storage => { 'Alt::Storage::Class' => \%options },
    );

    # simple functions and class methods - can store all arguments
    $mocker->mock("Their::Package::Method");

    # object methods - we need to turn $_[0] ($self) into an
    # unique identifier for object, not memory reference
    $mocker->mock( "Their::Object::Method",
        sub { $_[0]->firstname . '-' . $_[0]->lastname } );

    # do the same for other arguments
    $mocker->mock(
        "Their::Object::Method",
        sub {
            (   $_[0],                                       # use as-is
                $_[1]->firstname . '-' . $_[1]->lastname,    # object in $_[1]
                 # no need to list further arguments if no more changes required
            );
        }
    );

    # skipping arguments that shouldn't be saved - set to undef
    $mocker->mock(
        "Their::Package::Method",
        sub {
            (   $_[0],    # keep
                undef,    # discard

                # further args kept as-is
            );
        }
    );

# DESCRIPTION

Record and playback method arguments, for convenient mocking in tests.

With this module it is possible to easily replace an expensive, external or
non-repeatable call, so that there is no need to make that call again during
subsequent testing.

This module aims to be low-dependency to minimise disruption with legacy
codebases.  By default tries to use [Test::MethodFixtures::Storage::File](https://metacpan.org/pod/Test::MethodFixtures::Storage::File) to
record method data.  Other storage classes can be provided instead, to use
modules available to your system.

**N.B.** This module should be considered ALPHA quality and liable to change.

Despite not providing any test methods, it is under the `Test::` namespace to
aid discovery and because it makes little sense outside of a test environment.
The name is inspired by database 'fixtures'.

Feedback welcome!

# METHODS

## new

    my $mocker = Test::MethodFixtures->new(
        {   mode    => 'record',            # override global / ENV
            storage => '/path/to/storage',  # override default storage directory

            # or use alternative Test::MethodFixtures::Storage object
            storage => $storage_obj,

            # or load alternative Test::MethodFixtures::Storage:: class
            storage => { 'Alt::Storage::Class' => \%options },
        }
    );

Class method. Constructor

## mock

    $mocker->mock("Their::Package::method");
    $mocker->mock( "Their::Package::method", sub { ( $_[0], ... ) } );

In `record` mode stores the return values of the named method against the
arguments passed through to generate those return values.

In `playback` mode retrieves stored return values of the named method for the
arguments passed in.

In `passthrough` mode the arguments and return values are passed to and from
the method as normal (i.e. turns off mocking).

The arguments passed to the mocked method are used to create the key to store
the results against.

Optionally `mock()` takes a second argument of a coderef to manipulate `@_`,
for example to prevent storage of a non-consistent value or to stringify an
object to a unique identifier.

# BEHAVIOUR

- Warns if the module versions used to create the saved data is more recent
than those currently running.
- Handles calling context (list or scalar). Satisfies code using `wantarray`.

# RATIONALE

Testing is good, but also hard to do well, especially with complex systems. This
module aims to provide a simple way to help isolate code for testing, and get
closer to true "unit testing".

## Why not mock objects?

Mock objects are a good way to satisfy simple dependencies, but have many
drawbacks, especially in complex systems:

- They require writing of more code (more development time and more chances for
bugs). The mocking code may end up being a duplication of existing behaviour of
the mocked code.
- They have to be kept up-to-date with the code that they are mocking, yet are
not usually stored with that code or maintained by the same developers. Besides
the extra development costs, divergence may only be noticed later and so the
tests are of less value.

## Further reading

- https://www.destroyallsoftware.com/blog/2014/test-isolation-is-about-avoiding-mocks

# SEE ALSO

- [LWP::UserAgent::Mockable](https://metacpan.org/pod/LWP::UserAgent::Mockable)
- [Memoize](https://metacpan.org/pod/Memoize)

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/mjemmeson/Test-MethodFixtures/issues](https://github.com/mjemmeson/Test-MethodFixtures/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

[https://github.com/mjemmeson/Test-MethodFixtures](https://github.com/mjemmeson/Test-MethodFixtures)

    git clone git://github.com/mjemmeson/Test-MethodFixtures.git

# AUTHOR

Michael Jemmeson <mjemmeson@cpan.org>

# COPYRIGHT

Copyright 2015- Michael Jemmeson

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
