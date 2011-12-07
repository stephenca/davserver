package HTTP::DAV::Server::Logging;
use common::sense 3.4;

use File::Spec    3.33;

use Sub::Exporter 0.982
  -setup => { exports => [ qw(init_access_logging) ] };

# Version set by dist.ini. Do not change here.
# VERSION
 
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

1;
