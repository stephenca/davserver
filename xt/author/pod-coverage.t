#!perl -T

use warnings;
use strict;

use Test::More;

eval { require Test::Pod::Coverage; };

if ( $@ ) {
  plan( skip_all => 'Test::Pod::Coverage not found'  );
}

Test::Pod::Coverage::all_pod_coverage_ok();
