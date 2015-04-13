package TestMethodFixtures::Dummy;

use strict;
use warnings;

use Digest::MD5 qw( md5_hex );
use Storable qw( freeze );

use base 'Test::MethodFixtures::Storage';

my %STORAGE;

use Data::Dump qw/ dd /;

sub store {
    my ( $self, $args ) = @_;

    $STORAGE{ $args->{method} }->{ _key( $args->{key}) }
        = { input => $args->{input}, output => $args->{output} };

    return $self;
}

sub retrieve {
    my ( $self, $args ) = @_;

    die unless $self->is_stored($args);

    return $STORAGE{ $args->{method} }->{ _key( $args->{key} ) };
}

sub is_stored {
    my ( $self, $args ) = @_;

    return exists $STORAGE{ $args->{method} }->{ _key( $args->{key} ) } ? 1 : 0;
}

sub _key {
    return md5_hex freeze shift;
}

1;

