#!/usr/bin/env perl
use common::sense      3.4;
use Directory::Scratch 0.14;
use Test::Most         0.22;

use HTTP::DAV::Server::Logging qw(:all);

my $tmpdir = Directory::Scratch->new;

my $logfile = $tmpdir->touch( 'access.log' );

my $logfh = init_access_logging( "$logfile" );

done_testing;
