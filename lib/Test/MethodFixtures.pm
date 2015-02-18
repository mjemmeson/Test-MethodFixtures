use strict;
use warnings;

package Test::MethodFixtures;

our $VERSION = '0.01';

use Carp;
use Data::Dump qw( dump );
use Digest::MD5 qw( md5_hex );;
use Hook::LexWrap qw( wrap );
use Path::Tiny;
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

    return $class->SUPER::new(
        {   mode => $mode || 'playback',    #
            storage  => 't/.methodfixtures',
            _wrapped => {},
            %args,
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

    my $dump = dump { input => $input, output => $output, version => $VERSION };

    # for now only store on disk
    my $storage = path( $self->storage, $method );
    $storage->mkpath;
    $storage->child($key)->spew_utf8($dump);

    return $self;
}

sub retrieve {
    my ( $self, $args ) = @_;

    my $method = $args->{method} or croak "'method' missing";
    my $key    = $args->{key}    or croak "'key' missing";
    my $input  = $args->{input}  or croak "'input' missing";

    my $storage = path( $self->storage, $method );
    my $stored = $storage->child($key)->slurp_utf8();

    my $data = eval $stored;
    return $data->{output};
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
        return md5_hex dump( $config, @args );
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

=head1 NAME

Test::MethodFixtures

=head1 DESCRIPTION

Record and playback method arguments, for easy mocking in tests.

Replace an expensive or external call, so that don't need to repeatedly make
that call during testing.

=head1 SYNOPSIS

    use Test::MethodFixtures mode => 'record';

    my $mocker = Test::MethodFixtures->new( mode => 'record' );

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

=head1 TODO

=over

=item *

probably need to handle when same method called in scalar and list context

=back

=cut

