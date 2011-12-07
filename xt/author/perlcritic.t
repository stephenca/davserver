#!perl -T

use warnings;
use strict;

use File::Spec;
use Test::More;

eval { require Test::Perl::Critic; };

if ( $@ ) {
  plan( skip_all => 'Test::Perl::Critic not found'  );
}

my $rcfile = File::Spec->catfile( 'xt', 'author', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile
                          , -exclude => 
                            [ 'TestingAndDebugging::RequireUseStrict'
                            , 'TestingAndDebugging::RequireUseWarnings' ] );

all_critic_ok();
