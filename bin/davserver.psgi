#!/usr/bin/env perl

use common::sense  3.4;

use Carp                qw(carp croak cluck confess);
use Config::Any    0.23;

use Data::Dumper;

use File::Spec     3.33;

use Hash::Merge    0.12 qw(merge);

use Log::Log4perl  1.33;

use Plack::Builder;
use Plack::Request;
use Plack::Response;

use Sub::Call::Tail 0.04;
use Try::Tiny      0.06;

use XML::Tiny      2.06;  # for parsing
use XML::Writer    0.612; # for responses

sub do_config {
  my $config_path = shift || $ENV{DAVCONFIGPATH} || '.';
  my $config_file = shift || $ENV{DAVCONFIG};

  my $cfg = [];
  if(defined($config_file)) {
    my $cfile = File::Spec->catfile( $config_path, $config_file );
    $cfg = Config::Any->load_files( { files => [$cfile] } );
  }
  else {
    $cfg  = 
      Config::Any->load_stems( 
        { stems => [File::Spec->catfile( $config_path, 'davserver' )] } );
  }

  my @config_vals = map { values %{$_} } @{$cfg};
  return @config_values 
       ? %{ merge( @config_vals ) }
       : ();
}

sub init_access_logging {
  my $access_log = shift;

  # Set up access log for middleware.
  my $access_log = defined($access_log)
                 ?         $access_log
                 : File::Spec->devnull;
  open( my $logfh, ">>", $access_log )
              or die( "File to open $access_log: $!" );
  $logfh->autoflush(1);

  return $logfh;
}

sub GET_handler {
  my $r = shift;
  my $res = Plack::Response->new(200);
     $res->content_type('text/html');
     $res->body("Hello World");

  return $res->finalize;
}

sub PF_handler {
  my $r = shift;

  my $req   = Plack::Request->new($r);
  my $depth = $req->headers('Depth') || 1;

  my $xml;
  my $ns = 'DAV:';
  my $writer = XML::Writer->new( OUTPUT     => \$xml
                               , NAMESPACES => 1
                               , PREFIX_MAP => {$ns => 'D'} );

     $writer->xmlDecl('UTF-8');
     $writer->startTag([$ns => 'multistatus']);

      $writer->startTag([$ns => 'response']);
       # href
       $writer->dataElement( [$ns => 'href']
                           , 'http://localhost:5000/');

       #propstat
       $writer->startTag([$ns => 'propstat']);
        # status
        $writer->dataElement( [$ns => 'status']
                            , 'HTTP/1.1 200 OK');
 
        $writer->startTag([$ns => 'prop']);
         $writer->dataElement( [$ns => 'resourcetype']
                             , 'collection');
        $writer->endTag([$ns => 'prop']);
       $writer->endTag([$ns => 'propstat']);

      $writer->endTag([$ns => 'response']);
     $writer->endTag([$ns => 'multistatus']);

     $writer->end;

  return[207,['Content-Type','text/xml'],[$xml]];
}

my %config = do_config( 't/etc' );
my $logfh  = init_access_logging($config{server}{access_log});

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
