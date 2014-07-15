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

if (@ARGV != 7)
{
  print STDERR "Usage: $0 <diablo listing> <instruction trace> <0: original trace, 1: Diablo trace> <instruction list file> <old address list file> <mapping instruction to trace line nr file> <processed trace>\n";
  exit 1;
}

my $diabloListing = $ARGV[0];
my $tracefile = $ARGV[1];
my $origDiablo = $ARGV[2];

my $outIns = $ARGV[3];
my $outOld = $ARGV[4];
my $outMap = $ARGV[5];
my $outPtr = $ARGV[6];

my $isDiabloTrace = 0;
if ($origDiablo == 1)
{
  $isDiabloTrace = 1;
}

{
  print "Reading Diablo listing: $diabloListing\n";
  my %diabloListOldToNew;
  my %diabloListNewToOld;
  open my $diabloListingFileHandle, '<', $diabloListing or die "Error: failed to open Diablo list file $diabloListing\n";
  read_diablo_listing($diabloListingFileHandle, \%diabloListOldToNew, \%diabloListNewToOld);
  close $diabloListingFileHandle;

  #print Dumper(\%diabloListNewToOld);

  open my $traceHandle, '<', $tracefile or die "Error: failed to open instruction trace file $tracefile\n";

  open my $insH, '>', $outIns or die "Error: failed to open output file $outIns\n";
  open my $oldH, '>', $outOld or die "Error: failed to open output file $outOld\n";
  open my $mapH, '>', $outMap or die "Error: failed to open output file $outMap\n";
  open my $ptrH, '>', $outPtr or die "Error: failed to open output file $outPtr\n";

  my $line;
  my @lines;
  my $found = 0;
  my $foundNR = 0;
  while (<$traceHandle>)
  {
    $line = $_;

    next if (($found == 0) and ($line !~ m/^=>/));

    if ($line =~ m/^=>/)
    {
      push @lines, $line;
      $found = 1;
      $foundNR = $.;
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
      my $old;
      if ($isDiabloTrace)
      {
        $old = sprintf("%x", $diabloListNewToOld{hex($addr)});
        $addressTrans = sprintf("Old: 0x%s\tNew: 0x%x\t", $old, hex($addr));
      }
      else
      {
        $old = sprintf("%x", $addr);
        $addressTrans = sprintf("Old: 0x%s\tNew: 0x%x\t", $old, $diabloListOldToNew{hex($addr)});
      }

      $final_line =~ s/^=>[^>]*>:\s*//;
      $final_line =~ s/<[^>]*>$//;

      print $insH "$addressTrans $final_line\n";
      print $oldH "0x$old\n";
      print $mapH "$foundNR\n";

      print $ptrH "$old $final_line\n";
      for (my $i = 0; $i <= 16; $i++) {
        print $ptrH "\t$line";
        $line = <$traceHandle>;
      }

      $found = 0;
      @lines = ();
    }
  }

  close $traceHandle;
  close $insH;
  close $oldH;
  close $mapH;
  close $ptrH;
}