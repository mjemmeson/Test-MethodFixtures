package Test::MethodFixtures::Storage::File;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Data::Dump qw( dump );
use Digest::MD5 qw( md5_hex );;
use Path::Tiny;
use version;

use base 'Test::MethodFixtures::Storage';

__PACKAGE__->mk_accessors(qw/ dir /);

sub store {
    my ( $self, $args ) = @_;

    my $method  = $args->{method};
    my $key     = $args->{key};
    my $input   = $args->{input};
    my $output  = $args->{output};
    my $version = $args->{version};

    my $dump = dump { input => $input, output => $output, version => $version };

    # for now only store on disk
    my $storage = path( $self->dir, $method );
    $storage->mkpath;
    $storage->child( $self->filename($key) )->spew_utf8($dump);

    return $self;
}

sub retrieve {
    my ( $self, $args ) = @_;

    my $method  = $args->{method};
    my $key     = $args->{key};
    my $input   = $args->{input};
    my $version = $args->{version};

    my $storage = path( $self->dir, $method );
    my $stored = $storage->child( $self->filename($key) )->slurp_utf8();

    my $data = eval $stored;

    my $v_this = version->parse($version);
    my $v_that = version->parse( $data->{version} );
    carp "Data saved with a more recent version of Test::MethodFixtures!"
        if $v_that > $v_this;

    return $data->{output};
}

sub filename {
    my ( $self, $key ) = @_;

    return md5_hex dump $key;
}

1;

__END__

=pod

=head1 NAME

Test::MethodFixtures::Storage::File

=head1 SYNOPSIS

    my $storage = Test::MethodFixtures::Storage::File->new(
        { dir => '/path/to/storage' } );

    $storage->store({ method => ..., input => ..., output =>..., key => ..., 

=head1 DESCRIPTION

=cut

