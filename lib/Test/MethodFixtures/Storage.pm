package Test::MethodFixtures::Storage;

use strict;
use warnings;

use Carp;

use base 'Class::Accessor::Fast';

sub store    { croak "store() not implemented" }
sub retrieve { croak "retrieve() not implemented" }

1;

__END__

=pod

=head1 NAME

Test::MethodFixtures::Storage

=head1 DESCRIPTION

Base class for storage objects for L<Test::MethodFixtures>

=cut

