package Test::MockModule::Fixtures;

use strict;
use warnings;
use Carp;

use Hook::LexWrap qw( wrap );
use Data::Dump qw( dump );
use Digest::MD5 qw( md5_hex );;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw( stash mode ));

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

                my $key = $get_key->(@args);

                croak "Not found in cache"
                    unless exists $self->stash->{$name}->{$key};

                # add cached value into extra arg,
                # so original sub will not be called
                $_[-1] = $self->stash->{$name}->{$key};
            }
        };

        wrap $name => post => sub {

            if ( $self->mode eq 'record' ) {

                my (@args) = @_;
                my $result = pop @args;

                my $key = $get_key->(@args);

                # save response to cache
                $self->stash->{$name}->{$key} = $result;
            }
        };

    }

    return $self;
}

1;

__END__

=head1 NAME

=head1 DESCRIPTION

=head1 SYNOPSIS

    use Test::MockModule::Fixtures mode => 'record';

    my $tmmf = Test::MockModule::Fixtures->new("My::Module");


=cut

{
    my $module = new Test::MockModule('Module::Name');
    $module->mock('subroutine', sub { ... });
    Module::Name::subroutine(@args); # mocked
}
 
Module::Name::subroutine(@args); # original subroutine


 
sub doit { print "[doit:", caller, "]"; return {my=>"data"} }
 
@args = (4,5,6);
doit(@args);            # pre1->doit->post1


