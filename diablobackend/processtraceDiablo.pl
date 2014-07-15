#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;

sub read_diablo_listing {
  my ($fh, $instructionsOldToNew, $instructionsNewToOld) = @_;

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
        $instructionsOldToNew->{$oldAddress} = $newAddress;
        $instructionsNewToOld->{$newAddress} = $oldAddress;
      }
    } else {
      print "Warning: unrecognized text in list at line $.: $line\n";
    }
  }
}

if (@ARGV != 4)
{
  print STDERR "Usage: $0 <listing A> <trace A> <listing B> <trace B>\n";
  exit 1;
}

my $listA = $ARGV[0];
my $traceA = $ARGV[1];
my $listB = $ARGV[2];
my $traceB = $ARGV[3];

{
  print "Reading Diablo listing: $listA\n";
  my %listAOldToNew;
  my %listANewToOld;
  open my $listAhandle, '<', $listA or die "Error: failed to open Diablo list file $listA\n";
  read_diablo_listing($listAhandle, \%listAOldToNew, \%listANewToOld);
  close $listAhandle;

  print "Reading Diablo listing: $listB\n";
  my %listBOldToNew;
  my %listBNewToOld;
  open my $listBhandle, '<', $listB or die "Error: failed to open Diablo list file $listB\n";
  read_diablo_listing($listBhandle, \%listBOldToNew, \%listBNewToOld);
  close $listBhandle;

  open my $traceHandle, '<', $tracefile or die "Error: failed to open instruction trace file $tracefile\n";

  my $line;
  my @lines;
  my $found = 0;
  while (<$traceHandle>)
  {
    $line = $_;

    next if (($found == 0) and ($line !~ m/^=>/));

    if ($line =~ m/^=>/)
    {
      push @lines, $line;
      $found = 1;
    }
    elsif ($line =~ m/^\s+/)
    {
      push @lines, $line;
    }
    else
    {
      # all lines have been found, concat them to one line
      my $final_line = join(' ', @lines);
      $final_line =~ s/\n//g;

      # extract address
      $final_line =~ m/^=>\s*([^\s]*)/;
      die if !defined($1);
      my $addr = $1;
      my $addressTrans = "";
      if ($isDiabloTrace)
      {
        $addressTrans = sprintf("Old: 0x%x\tNew: 0x%x\t", $diabloListNewToOld{hex($addr)}, hex($addr));
      }
      else
      {
        $addressTrans = sprintf("Old: 0x%x\tNew: 0x%x\t", hex($addr), $diabloListOldToNew{hex($addr)});
      }

      $final_line =~ s/^=>[^>]*>:\s*//;
      $final_line =~ s/<[^>]*>$//;
      print "$addressTrans $final_line\n";

      $found = 0;
      @lines = ();
    }
  }
}