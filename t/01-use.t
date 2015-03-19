use Test::More;

use strict;
use warnings;

use FindBin '$Bin';
use Module::Util;

BEGIN {

    my @modules = Module::Util::find_in_namespace( '', "$Bin/../lib" );

    foreach my $module ( sort @modules ) {
        use_ok($module);
    }
}

done_testing();

1;

