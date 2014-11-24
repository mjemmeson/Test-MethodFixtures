package Test::MethodFixtures;

use strict;
use warnings;
use Carp;

use Hook::LexWrap qw( wrap );
use Data::Dump qw( dump );
use Digest::MD5 qw( md5_hex );;
use Path::Tiny;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw( mode storage ));

my $mode;

sub import {
    my ( $class, %args ) = @_;

    if ( $mode = $args{'-mode'} || '' ) {
        croak "Invalid mode '$mode'"
            unless $mode eq 'playback' or $mode eq 'record';
    }
}

sub new {
    my ( $class, %args ) = @_;

    return $class->SUPER::new(
        {   $mode ? ( mode => $mode ) : (),    #
            stash => {},
            %args,
        }
    );
}

sub store {
    my ( $self, $method, $key, $input, $output ) = @_;

    # for now only store on disk
    my $storage = path( $self->storage || '.methodfixtures', $method );
    $storage->mkpath;
    $storage->child($key)
        ->spew_utf8( dump { input => $input, output => $output } );

    return $self;
}

sub retrieve {
    my ( $self, $method, $key, $input ) = @_;

    my $storage = path( $self->storage || '.methodfixtures', $method );
    my $stored = $storage->child($key)->slurp_utf8();

    my $data = eval $stored;

    return $data->{output};
}

sub mock {
    my $self = shift;

    while ( my ( $name, $value ) = splice @_, 0, 2 ) {

        my $get_key = sub {
            my @args = @_;
            if ($value) {
                my @replace = $value->(@args);
                splice( @args, 0, scalar(@replace), @replace );
            }

            return md5_hex dump @args;
        };

        wrap $name => pre => sub {

            if ( $self->mode eq 'playback' ) {

                my @args = @_;
                pop @args;    # will be the return value

                # add cached value into extra arg,
                # so original sub will not be called
                $_[-1] = $self->retrieve( $name, $get_key->(@args), \@args );
            }
        };

        wrap $name => post => sub {

            if ( $self->mode eq 'record' ) {

                my (@args) = @_;
                my $result = pop @args;

                $self->store( $name, $get_key->(@args), \@args, $result );
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

    my $mocker = Test::MethodFixtures( mode => 'record' );

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
