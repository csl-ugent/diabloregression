#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;

sub read_diablo_listing {
  my ($fh, $instructions) = @_;

  my $line;

  print "Warning: ignoring DATA instructions\n";

  while(<$fh>) {
    $line = $_;

    chomp $line;

    if ($line =~ m/^New\s+0x([0-f]+)\s+Old\s+0x([0-f]+)\s+:\s+(.*)$/) {
      my $newAddress = hex($1);
      my $oldAddress = hex($2);
      my $instruction = $3;

      if ($instruction =~ m/^DATA/) {
        #print "Warning: ignoring data in list at line $.: $line\n";
      } else {
        $instructions->{$oldAddress} = $instruction;
      }
    } else {
      print "Warning: unrecognized text in list at line $.: $line\n";
    }
  }
}

if (@ARGV != 1)
{
  print STDERR "Usage: $0 <listing>\n";
  exit 1;
}

my $diabloListing = $ARGV[0];

my %instructions;
open my $diabloListingFileHandle, '<', $diabloListing or die "Error: failed to open Diablo list file $diabloListing\n";
read_diablo_listing($diabloListingFileHandle, \%instructions);

foreach my $key (sort {$a<=>$b} keys %instructions)
{
  print "", sprintf("%08x", $key), "   ", $instructions{$key}, "\n";
}
