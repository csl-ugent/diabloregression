#!/usr/bin/perl -w

use strict;
use warnings;

require "objdump.pm";
require "diablo.pm";

my $origDump = $ARGV[0];
my $diabloDump = $ARGV[1];
my $diabloListing = $ARGV[2];

{
  print "Reading original dump: $origDump\n";
  my %origIns;
  open my $origFileHandle, '<', $origDump or die "Error: failed to open original dump file $origDump\n";
  read_dump($origFileHandle, \%origIns);
  close $origFileHandle;

  print "Reading diablo dump: $diabloDump\n";
  my %diabloIns;
  open my $diabloFileHandle, '<', $diabloDump or die "Error: failed to open diablo dump file $diabloDump\n";
  read_dump($diabloFileHandle, \%diabloIns);
  close $diabloFileHandle;

  print "Reading Diablo listing: $diabloListing\n";
  my %diabloListOldToNew;
  open my $diabloListingFileHandle, '<', $diabloListing or die "Error: failed to open Diablo list file $diabloListing\n";
  read_diablo_listing($diabloListingFileHandle, \%diabloListOldToNew);
  close $diabloListingFileHandle;

  # also make a reverse index
  my %diabloListNewToOld;
  foreach my $oldAddress (keys %diabloListOldToNew) {
    $diabloListNewToOld{$diabloListOldToNew{$oldAddress}} = $oldAddress;
  }

  print "Opening output files\n";
  my $origOutName = 'a.list';
  open my $origOutHandle, '>', $origOutName or die "Error: failed to open output 1 $origOutName\n";
  my $diabloOutName = 'b.list';
  open my $diabloOutHandle, '>', $diabloOutName or die "Error: failed to open output 2 $diabloOutName\n";

  #print $origOutHandle "";
  foreach my $oldAddress (keys %origIns)
  {
    if (exists $diabloListOldToNew{$oldAddress})
    {
      # the instruction in the original binary at old address OldAddress still exists in the Diablo binary
      my $newAddress = $diabloListOldToNew{$oldAddress};

      print $origOutHandle   "$origIns{$oldAddress}{opcode} $origIns{$oldAddress}{mnemonic} $origIns{$oldAddress}{operands}\n";
      print $diabloOutHandle "$diabloIns{$newAddress}{opcode} $diabloIns{$newAddress}{mnemonic} $diabloIns{$newAddress}{operands}\n";
    }
    else
    {
      # the instruction in the original binary at old address OldAddress does not exist anymore in the Diablo binary
      print $origOutHandle   "$origIns{$oldAddress}{opcode} $origIns{$oldAddress}{mnemonic} $origIns{$oldAddress}{operands}\n";
      print $diabloOutHandle "\n";
    }
  }

  close $origOutHandle;
  close $diabloOutHandle;
}
