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

sub import {
    my ( $class, %args ) = @_;

    if ( $MODE = $args{'-mode'} ) {
        croak "Invalid mode '$MODE'"
            unless $MODE eq 'playback' or $MODE eq 'record';
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

            if ( $self_ref->mode eq 'playback' ) {

                my @args = @_;
                pop @args;    # will be the return value

                my $key = $get_key->( { 'wantarray' => wantarray }, @args );

                # add cached value into extra arg,
                # so original sub will not be called
                $_[-1] = $self_ref->retrieve(
                    {   method => $name,
                        key    => $key,
                        input  => \@args,
                    }
                );
            }
        };

        $self->_wrapped->{"$name-post"} = wrap $name => post => sub {

            if ( $self_ref->mode eq 'record' ) {

                my (@args) = @_;
                my $result = pop @args;

                my $key = $get_key->( { 'wantarray' => wantarray }, @args );

                $self_ref->store(
                    {   method => $name,
                        key    => $key,
                        input  => \@args,
                        defined wantarray
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
        # optionally specify arguments
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
        storage => { AltStorage => \%options },
    );

    # simple function - can store all arguments
    $mocker->mock("My::Package::Method");

    # object method - need to turn $_[0] ($self) into an
    # identifier for object, not memory reference
    $mocker->mock( "My::Object::Method",
        sub { $_[0]->firstname . '-' . $_[0]->lastname } );

    # do the same for other arguments
    $mocker->mock(
        "My::Package::Method",
        sub {
            (   $_[0],                                       # use as-is
                $_[1]->firstname . '-' . $_[1]->lastname,    # object in $_[1]
                 # no need to list further arguments if no more changes required
            );
        }
    );

=head1 DESCRIPTION

Record and playback method arguments, for convenient mocking in tests.

Using this module you can replace an expensive, external or non-repeatable call,
so that there is no need to make that call during subsequent testing.

=head1 METHODS

=head2 new

Class method. Constructor

=cut

