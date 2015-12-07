package Test::MethodFixtures::Storage::File;

use strict;
use warnings;
use Carp;

our $VERSION = '0.06';

use Carp;
use Data::Dump qw( dump );
use Digest::MD5 qw( md5_hex );
use Path::Tiny;

use base 'Test::MethodFixtures::Storage';

__PACKAGE__->mk_accessors(qw/ dir /);

our $DEFAULT_DIR = 't/.methodfixtures';

sub new {
    my ( $class, $args ) = @_;

    $args ||= {};
    unless ($args->{dir}) {
        mkdir $DEFAULT_DIR;
        $args->{dir} = $DEFAULT_DIR;
    }

    croak "Unable to access " . $args->{dir}
        unless -d $args->{dir} && -w $args->{dir};

    return $class->SUPER::new($args);
}

sub store {
    my ( $self, $args ) = @_;

    my $method = delete $args->{method};
    my $key    = delete $args->{key};

    # for now only store on disk
    my $storage = path( $self->dir, $method );
    $storage->mkpath;
    $storage->child( $self->_filename($key) )->spew_utf8( dump $args );

    return $self;
}

sub retrieve {
    my ( $self, $args ) = @_;

    my $method = $args->{method};
    my $key    = $args->{key};

    my $storage = path( $self->dir, $method )->child( $self->_filename($key) );
    return unless $storage->is_file;

    my $data = eval $storage->slurp_utf8();;

    return $data;
}

sub _filename {
    my $self = shift;
    return md5_hex dump shift;
}

1;

__END__

=pod

=head1 NAME

Test::MethodFixtures::Storage::File - Simple file storage for method mocking with Test::MethodFixtures

=head1 SYNOPSIS

    my $storage = Test::MethodFixtures::Storage::File->new(
        {   dir => 't/.methodfixtures'    # default
        }
    );

=head1 DESCRIPTION

Subclass of L<Test::MethodFixtures::Storage>. Implements C<store> and C<retrieve>

=head1 METHODS

=head2 new

    my $storage = Test::MethodFixtures::Storage::File->new( \%args );

Class method. Constructor.

Will die if the storage directory does not exist and cannot be written to. Will
create the storage directory if the default (C<<t/.methodfixtures>>) is used.

=head2 store

Object method. Stores to file.

=head2 retrieve

Object method. Retrieves from file. Empty return if not found (i.e. nothing stored).

=cut

