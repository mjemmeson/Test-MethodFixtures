use strict;
use warnings;

package Test::MethodFixtures;

our $VERSION = '0.01';

use Carp;
use Hook::LexWrap qw( wrap );
use Scalar::Util qw( weaken blessed );
use version;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw( mode storage _wrapped ));

our ( $MODE, $STORAGE );
my %VALID_MODES = ( playback => 1, record => 1, auto => 1 );

sub import {
    my ( $class, %args ) = @_;

    if ( $MODE = $args{'-mode'} ) {
        croak "Invalid mode '$MODE'"
            unless $VALID_MODES{$MODE};
    }

    $STORAGE = $args{'-storage'};
}

sub new {
    my ( $class, $args ) = @_;

    my $mode     = $args->{mode}     || $MODE;
    my $storage  = $args->{storage}  || $STORAGE;

    return $class->SUPER::new(
        {   mode => $mode || 'playback',
            storage  => _get_storage($storage),
            _wrapped => {},
        }
    );
}

sub _get_storage {
    my $storage = shift;

    return $storage if ref $storage && blessed $storage;

    my ( $storage_class, $storage_args );

    if ( ref $storage ) {

        ( $storage_class, $storage_args ) = %{$storage};

        unless ( $storage_class =~ s/^\+// ) {
            $storage_class = "Test::MethodFixtures::Storage::$storage_class";
        }

    } else {

        $storage_class = 'Test::MethodFixtures::Storage::File';
        $storage_args = { dir => $storage };

    }

    eval "require $storage_class" ;
    croak "Unable to load '$storage_class': $@" if $@;

    return $storage_class->new($storage_args);
}

sub store {
    my $self = shift;

    my %args = %{ shift() };

    $args{ ref $self } = $self->VERSION;
    $args{ ref $self->storage } = $self->storage->VERSION;

    $self->storage->store( { %args, version => $VERSION } );

    return $self;
}

sub retrieve {
    my ( $self, $args ) = @_;

    my $stored = $self->storage->retrieve($args);

    _compare_versions( $self,          $stored->{version} );
    _compare_versions( $self->storage, $stored->{storage_version} );

    return $stored->{output};
}

sub is_stored {
    my ( $self, $args ) = @_;

    return $self->storage->is_stored($args);
}

sub _compare_versions {
    my ( $class, $version ) = @_;

    carp "Data saved with a more recent version ($version) of "
        . ref($class) . "!"
        if version->parse( $class->VERSION ) < version->parse($version);
}

# pass in optional coderef to return list of values to use
# (for example to stringify objects)
sub get_key_sub {
    my ( $self, $value ) = @_;

    return sub {
        my ( $config, @args ) = @_;
        if ($value) {
            my @replace = $value->(@args);
            splice( @args, 0, scalar(@replace), @replace );
        }
        return [ $config, @args ];
    };
}

sub mock {
    my $self = shift;

    my $self_ref = $self;
    weaken $self_ref;    # otherwise reference to $self within wrapped methods

    while ( my ( $name, $value ) = splice @_, 0, 2 ) {

        my $get_key = $self->get_key_sub($value);

        $self->_wrapped->{"$name-pre"} = wrap $name => pre => sub {

            my @args = @_;    # original arguments method received
            pop @args;        # currently undef, will be the return value

            my $key = $get_key->( { wantarray => wantarray() }, @args );

            if (   $self_ref->mode eq 'playback'
                or $self_ref->mode eq 'auto'
                && $self_ref->is_stored( { method => $name, key => $key } ) )
            {

                # add cached value into extra arg,
                # so original sub will not be called
                eval {
                    $_[-1] = $self_ref->retrieve(
                        {   method => $name,
                            key    => $key,
                            input  => \@args,
                        }
                    );
                };
                if ($@) {
                    croak "Unable to retrieve $name - in "
                        . $self_ref->mode . " mode";
                }
            }
        };

        $self->_wrapped->{"$name-post"} = wrap $name => post => sub {

            my (@args) = @_;    # origin arguments method received, plus result
            my $result = pop @args;

            my $key = $get_key->( { wantarray => wantarray() }, @args );

            if (   $self_ref->mode eq 'record'
                or $self_ref->mode eq 'auto'
                && !$self_ref->is_stored( { method => $name, key => $key } ) )
            {

                $self_ref->store(
                    {   method => $name,
                        key    => $key,
                        input  => \@args,
                        defined wantarray()
                        ? ( output => $result )
                        : ( no_output => 1 ),
                    }
                );
            }
        };
    }

    return $self;
}

1;

__END__

=pod

=head1 NAME

Test::MethodFixtures

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Record and playback method arguments, for convenient mocking in tests.

Using this module you can replace an expensive, external or non-repeatable call,
so that there is no need to make that call during subsequent testing.

Aims to be low-dependency to minimise disruption with legacy codebases.

=head1 METHODS

=head2 new

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

=head2 mock

    $mocker->mock("My::Package::method");
    $mocker->mock( "My::Package::method", sub { ( $_[0], ... ) } );

In C<record> mode stores the return values of the named method against the
arguments passed through to generate those return values.

In C<playback> mode retrieves stored return values of the named method for
the arguments passed in.

The arguments are used to create the key to store the results against.

Optionally takes a second argument of a coderef to manipulate C<@_>, for
example to prevent storage of a non-consistent value or to stringify an
object to a unique identifier.

=cut

