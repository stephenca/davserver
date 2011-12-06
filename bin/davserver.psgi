#!/usr/bin/env perl

use common::sense  3.4;

use Carp                qw(carp croak cluck confess);
use Config::Std    0.007;

use Data::Dumper;

use File::Spec     3.33;

use Log::Log4perl  1.33;

use Plack::Builder;
use Plack::Request;
use Plack::Response;

use Sub::Call::Tail 0.04;
use Try::Tiny      0.06;

use XML::Tiny      2.06;  # for parsing
use XML::Writer    0.612; # for responses

my $config_file = $ENV{DAVCONFIG};

my %config;
if($config_file) {
  read_config( $config_file, %config );
}

# Set up access log for middleware.
my $access_log = exists( $config{access_log} ) 
               ?         $config{access_log}
               : File::Spec->devnull;
open( my $logfh, ">>", $access_log )
            or die( "File to open access_log: $!" );
$logfh->autoflush(1);

sub GET_handler {
  my $r = shift;
  my $res = Plack::Response->new(200);
     $res->content_type('text/html');
     $res->body("Hello World");

  return $res->finalize;
}

sub PF_handler {
  my $r = shift;

  my $req = Plack::Request->new($r);

  my $xml;
  my $ns = 'DAV:';
  my $writer = XML::Writer->new( OUTPUT     => \$xml
                               , NAMESPACES => 1
                               , PREFIX_MAP => {$ns => 'D'} );
     $writer->xmlDecl('UTF-8');
     $writer->startTag([$ns => 'multistatus']);
      $writer->startTag([$ns => 'response']);
       # href
       $writer->startTag([$ns => 'href']); 
        $writer->characters('http://localhost:5000/');
       $writer->endTag([$ns => 'href']);
       $writer->startTag([$ns => 'propstat']);
        # status
        $writer->startTag([$ns => 'status']);
         $writer->characters('HTTP/1.1 403 Forbidden');
        $writer->endTag([$ns => 'status']);

        $writer->startTag([$ns => 'prop']);
         $writer->startTag([$ns => 'resourcetype']);
          #$writer->emptyTag([$ns => 'collection']);
          $writer->characters('collection');
         $writer->endTag([$ns => 'resourcetype']);
        $writer->endTag([$ns => 'prop']);
       $writer->endTag([$ns => 'propstat']);
      $writer->endTag([$ns => 'response']);
     $writer->endTag([$ns => 'multistatus']);

  print($xml . "\n" );

  return[207,['Content-Type','text/xml'],[$xml]];
}

my %handlers = ( GET      => \&GET_handler
               , PROPFIND =>  \&PF_handler );

my $app = sub {
    my $r   = shift;

    warn(Dumper($r));

    if( exists($handlers{$r->{REQUEST_METHOD}}) )  {
      my $exec = $handlers{$r->{REQUEST_METHOD}};
      tail $handlers{$r->{REQUEST_METHOD}}->($r); 
    }
    else {
      return [500,[],[]];
    }
};

builder {
  # Deflator not for live use yet.
  #enable 'Deflater' =>
  #  content_type => ['text/html']
  #, vary_user_agent => 1;

  enable 'Options', allowed => [qw(POST GET HEAD PUT PROPFIND)];

  enable 'Plack::Middleware::AccessLog::Timed'
       , format => "%{X-forwarded-for}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"",
       , logger => sub { $logfh->print(@_) };

  $app;
};
