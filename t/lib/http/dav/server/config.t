#!/usr/bin/env perl
use common::sense      3.4;
use Cwd;
use Directory::Scratch 0.14;
use Test::Most         0.22;

use HTTP::DAV::Server::Config qw(:all);

sub test_config {
  my @args = @_;

  my %config;
  lives_ok { %config = build_config( @args ) }
           'build_config() runs';

  is_deeply( \%config
           , { server => { access_log => '/dev/null'
                         , docroot    => 't/httpdocs' } }
           , 'Got expected config' );

  return;
}

{ diag( 'Pass in two params' );

  for (qw(json std)) {
    diag( '.' . $_ . ' extension' );
    test_config( 't/etc/', "davserver.${_}" );
  }
}

{ diag('Pass in single param');

  test_config( 't/etc/' );
}

{ diag('No args');

  my $cwd = getcwd;
  chdir( 't/etc/' )
    or die("Can't chdir:$!");
  test_config;
  chdir( $cwd )
    or die("Can't chdir back to $cwd:$!" );
}

{ diag( 'Two ENV vars' );

  local(%ENV);

  $ENV{DAVCONFIGPATH} = 't/etc';

  for (qw(json std)) {
    diag( '.' . $_ . ' extension' );
    $ENV{DAVCONFIG} = "davserver.${_}";
    test_config;
  }
}

{ diag( 'Path ENV var only' );

  local(%ENV);

  $ENV{DAVCONFIGPATH} = 't/etc';

  test_config;  
}

{ diag( 'File ENV var only' );

  local(%ENV);

  my $cwd = getcwd;
  chdir( 't/etc/' )
    or die("Can't chdir:$!");

  for (qw(json std)) {
    diag( '.' . $_ . ' extension' );
    $ENV{DAVCONFIG} = "davserver.${_}";
    test_config;
  }

  chdir( $cwd )
    or die( "Can't chdir to $cwd:$!" );
}

done_testing;
