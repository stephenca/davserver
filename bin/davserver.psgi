#!/usr/bin/env perl

use common::sense  3.4;

use Carp                qw(carp croak cluck confess);
use Config::Std    0.007;

use Data::Dumper;

use File::Spec     3.33;

use Log::Log4perl  1.33;

use Plack::Builder;
use Plack::Response;

use Sub::Call::Tail 0.04;
use Try::Tiny      0.06;

use XML::Tiny      2.06;

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

my %handlers = ( GET => \&GET_handler );

my $app = sub {
    my $r   = shift;

    warn(Dumper($r));

    if( exists($handlers{$r->{REQUEST_METHOD}}) )  {
      my $exec = $handlers{$r->{REQUEST_METHOD}};
      warn( 'EXEC:' . ref($exec) );
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

  enable 'Options', allowed => [qw(POST GET HEAD PUT)];

  enable 'Plack::Middleware::AccessLog::Timed'
       , format => "%{X-forwarded-for}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"",
       , logger => sub { $logfh->print(@_) };

  $app;
};
