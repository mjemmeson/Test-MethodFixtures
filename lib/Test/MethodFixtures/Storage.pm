package Test::MethodFixtures::Storage;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

use base 'Class::Accessor::Fast';

sub store {
    my ( $self, $args ) = @_;

    $args->{ ref $self } = $VERSION;

    return $args;
}

sub retrieve { croak "retrieve() not implemented" }

__END__

=pod

=head1 NAME

Test::MethodFixtures::Storage

=head1 SYNOPSIS

Subclasses should implement the following interface:

    $storage->store(
        {   method => 'My::Module::mocked_method',
            key    => ...,
            input  => ...,
            output => ...,
        }
    );

    my $stored = $storage->retrieve(
        {   method => 'My::Module::mocked_method',
            key    => ...,
        }
    );

=head1 DESCRIPTION

Base class for storage objects for L<Test::MethodFixtures>

=cut

