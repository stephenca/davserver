#!perl -T

use warnings;
use strict;

use Test::More;

eval { require Test::Pod; };

if ( $@ ) {
  plan( skip_all => 'Test::Pod not found'  );
}

Test::Pod::all_pod_files_ok();
