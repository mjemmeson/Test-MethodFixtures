package Test::MethodFixtures::Storage;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp;

use base 'Class::Accessor::Fast';

sub store     { croak "store() not implemented" }
sub retrieve  { croak "retrieve() not implemented" }
sub is_stored { croak "is_stored() not implemented - can't use 'auto' mode" }

1;

__END__

=pod

=head1 NAME

Test::MethodFixtures::Storage - Base class for storage of data for methods mocked with Test::MethodFixtures 

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

    my $is_stored = $storage->is_stored(
        {   method => 'My::Module::mocked_method',
            key    => ...,
        }
    );
    if ($is_stored) {
        ...    # call retrieve()
    } else {
        ...    # call store()
    }

=head1 DESCRIPTION

Base class for storage objects for L<Test::MethodFixtures>

=cut

