package HTTP::DAV::Server::Config;

use common::sense 3.4;

use Config::Any   0.23;

use File::Spec    3.33;

use Hash::Merge   0.12 qw(merge);

use Sub::Exporter 0.982
  -setup => { exports => [qw(build_config)] };

# Version set by dist.ini. Do not change here.
# VERSION

sub build_config {
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
  return @config_vals 
       ? %{ merge( @config_vals ) }
       : ();
}

1;

# ABSTRACT: Configuration functions for HTTP::DAV::Server
