#!/usr/bin/perl -w

use strict;
use warnings;

require "llvm-objdump.pm";

if (@ARGV != 2)
{
  print STDERR "Usage: $0 <original llvm-objdump> <Diablo llvm-objdump>\n";
  exit 1;
}

my $origDump = $ARGV[0];
my $diabloDump = $ARGV[1];

{
  print "Reading original dump: $origDump\n";
  my %origIns;
  open my $origFileHandle, '<', $origDump or die "Error: failed to open original dump file $origDump\n";
  read_llvm_dump($origFileHandle, \%origIns);
  close $origFileHandle;

  print "Reading Diablo dump: $diabloDump\n";
  my %diabloIns;
  open my $diabloFileHandle, '<', $diabloDump or die "Error: failed to open Diablo dump file $diabloDump\n";
  read_llvm_dump($diabloFileHandle, \%diabloIns);
  close $diabloFileHandle;

  print "Comparing original with Diablo dump\n";
  foreach my $address (keys %origIns)
  {
    if (exists $diabloIns{$address})
    {
      if ($origIns{$address}{opcode} eq $diabloIns{$address}{opcode})
      {
        # ok
      }
      else
      {
        print STDERR "Error: instructions in original and Diablo dumps are not equal\n";
        print STDERR "       Original: $address $origIns{$address}{opcode} $origIns{$address}{mnemonic} $origIns{$address}{operands}\n";
        print STDERR "       Diablo  : $address $diabloIns{$address}{opcode} $diabloIns{$address}{mnemonic} $diabloIns{$address}{operands}\n";
      }
    }
    else
    {
      print STDERR "Address $address found in original dump, but not in the Diablo dump\n";
    }
  }
}
