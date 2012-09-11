#!/usr/bin/env perl

use common::sense  3.4;

use Carp                qw(carp croak cluck confess);

use Data::Dumper;

use File::Spec     3.33;

use HTTP::DAV::Server          qw(runapp :handlers);
use HTTP::DAV::Server::Config  qw(build_config);
use HTTP::DAV::Server::Logging qw(init_access_logging);

use Log::Log4perl  1.33;

use Plack::Builder;

use Sub::Call::Tail 0.04;
use Try::Tiny      0.06;

use XML::Tiny      2.06;  # for parsing

# Version set by dist.ini. Do not change here.
# VERSION

my %config = build_config( 't/etc/davserver.std' );
my $logfh  = init_access_logging($config{server}{access_log});

builder {
  # Deflator not for live use yet.
  #enable 'Deflater' =>
  #  content_type => ['text/html']
  #, vary_user_agent => 1;

  enable 'Options', allowed => [qw(POST GET HEAD PUT PROPFIND)];

  enable 'Plack::Middleware::AccessLog::Timed'
       , format => "%{X-forwarded-for}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"",
       , logger => sub { $logfh->print(@_) };

  \&runapp;
};


# ABSTRACT: abcdefg
# PODNAME: abcdefg
