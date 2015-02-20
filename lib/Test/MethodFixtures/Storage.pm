package Test::MethodFixtures::Storage;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

use base 'Class::Accessor::Fast';

sub store    { croak "store() not implemented" }
sub retrieve { croak "retrieve() not implemented" }

__END__

=pod

=head1 NAME

Test::MethodFixtures::Storage

=head1 SYNOPSIS

Subclasses should implement the following interface:

    $storage->store(
        {   method => 'My::Module::mocked_method',
            input  => ...,
            output => ...,
        }
    );


=head1 DESCRIPTION

Base class for storage objects for L<Test::MethodFixtures>

=cut

