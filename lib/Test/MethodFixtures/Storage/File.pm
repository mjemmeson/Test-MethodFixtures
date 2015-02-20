package Test::MethodFixtures::Storage::File;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Data::Dump qw( dump );
use Digest::MD5 qw( md5_hex );;
use Path::Tiny;

use base 'Test::MethodFixtures::Storage';

__PACKAGE__->mk_accessors(qw/ dir /);

sub new {
    my ( $class, $args ) = @_;

    $args ||= {};
    $args->{dir} ||= 't/.methodfixtures';

    return $class->SUPER::new($args);
}

sub store {
    my ( $self, $args ) = @_;

    my $method = $args->{method};
    my $key    = $args->{key};

    my $dump = dump {
        input           => $args->{input},
        output          => $args->{output},
        version         => $args->{version},
        storage_version => $VERSION,
    };

    # for now only store on disk
    my $storage = path( $self->dir, $method );
    $storage->mkpath;
    $storage->child( _filename($key) )->spew_utf8($dump);

    return $self;
}

sub retrieve {
    my ( $self, $args ) = @_;

    my $method  = $args->{method};
    my $key     = $args->{key};
    my $version = $args->{version};

    my $storage = path( $self->dir, $method );
    my $stored = $storage->child( _filename($key) )->slurp_utf8();

    my $data = eval $stored;

    return $data;
}

sub _filename {
    return md5_hex dump shift;
}

1;

__END__

=pod

=head1 NAME

Test::MethodFixtures::Storage::File

=head1 SYNOPSIS

    my $storage = Test::MethodFixtures::Storage::File->new(
        {   dir => 't/.methodfixtures'    # default
        }
    );

=head1 DESCRIPTION

Subclass of L<Test::MethodFixtures::Storage>. Implements C<store> and
C<retrieve> methods.

=cut

