#!/usr/bin/env perl
use common::sense      3.4;
use Directory::Scratch 0.14;
use File::Slurp        0.999918;
use Scalar::Util       1.23 qw();
use Test::Most         0.22;

use HTTP::DAV::Server::Logging qw(:all);

my $tmpdir = Directory::Scratch->new;

my $logfile = $tmpdir->touch( 'access.log' );

my $logfh;
lives_ok { $logfh  = init_access_logging( "$logfile" ) }
         'Call init_access_logging ok';

is(                          defined($logfh)
 && defined(Scalar::Util::openhandle($logfh))
, 1
, q[it returned a filehandle (as far as we can tell)] );

$logfh->print( "OK\n" );
$logfh->close;

my $c = read_file("$logfile");

is( $c
  , "OK\n"
  , ' .. and we can write to it.' );

done_testing;
