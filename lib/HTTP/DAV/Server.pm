package HTTP::DAV::Server;
use common::sense 3.4;

use Plack::Request;
use Plack::Response;

use Sub::Exporter 0.982
  -setup => { exports => [qw(GET_handler PF_handler)]
            , groups  => { handlers => [qw(GET_handler PF_handler)] } };

use XML::Writer   0.612;

# Version set by dist.ini. Do not change here.
# VERSION

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

1;

# ABSTRACT: DAV server implemented using Plack.
