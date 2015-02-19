use strict;
use warnings;

package Test::MethodFixtures;

our $VERSION = '0.01';

use Carp;
use Hook::LexWrap qw( wrap );
use Scalar::Util qw( weaken );

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw( mode storage _wrapped ));

our $mode;

sub import {
    my ( $class, %args ) = @_;

    if ( $mode = $args{'-mode'} ) {
        croak "Invalid mode '$mode'"
            unless $mode eq 'playback' or $mode eq 'record';
    }
}

sub new {
    my ( $class, %args ) = @_;

    my $storage = $args{storage};

    if ( ref $storage ) {

    } else {
        require Test::MethodFixtures::Storage::File;
        $storage = Test::MethodFixtures::Storage::File->new(
            { dir => $storage || 't/.methodfixtures' } );
    }

    return $class->SUPER::new(
        {   mode => $mode || 'playback',    #
            storage  => $storage,
            _wrapped => {},
        }
    );
}

sub store {
    my ( $self, $args ) = @_;

    my $method = $args->{method} or croak "'method' missing";
    my $key    = $args->{key}    or croak "'key' missing";
    my $input  = $args->{input}  or croak "'input' missing";
    my $output = $args->{output};
    croak "'output' missing" unless defined $output || $args->{no_output};

    $self->storage->store( { %{$args}, version => $VERSION } );

    return $self;
}

sub retrieve {
    my ( $self, $args ) = @_;

    my $method = $args->{method} or croak "'method' missing";
    my $key    = $args->{key}    or croak "'key' missing";
    my $input  = $args->{input}  or croak "'input' missing";

    return $self->storage->retrieve( { %{$args}, version => $VERSION } );
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

=head1 DESCRIPTION

Record and playback method arguments, for easy mocking in tests.

Replace an expensive or external call, so that don't need to repeatedly make
that call during testing.

=head1 SYNOPSIS

    use Test::MethodFixtures mode => 'record';

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

=cut

