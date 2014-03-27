#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;

require "objdump.pm";

if (@ARGV != 2)
{
  print STDERR "Usage: $0 <original objdump> <Diablo objdump>\n";
  exit 1;
}

my $origDump = $ARGV[0];
my $diabloDump = $ARGV[1];

{
  print "Reading original dump: $origDump\n";
  my %origIns;
  open my $origFileHandle, '<', $origDump or die "Error: failed to open original dump file $origDump\n";
  read_dump($origFileHandle, \%origIns);
  close $origFileHandle;

  print "Reading Diablo dump: $diabloDump\n";
  my %diabloIns;
  open my $diabloFileHandle, '<', $diabloDump or die "Error: failed to open Diablo dump file $diabloDump\n";
  read_dump($diabloFileHandle, \%diabloIns);
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
      elsif (($origIns{$address}{opcode} eq 'e320f000') and ($diabloIns{$address}{opcode} eq 'ebffffff'))
      {
        # ok: nop's can be replaced by BL's to the next address
      }
      elsif (($origIns{$address}{opcode} eq 'e320f000') and ($diabloIns{$address}{opcode} eq 'eaffffff'))
      {}
      elsif (($origIns{$address}{opcode} eq 'f3af8000') and ($diabloIns{$address}{opcode} eq 'f000f800'))
      {}
      else
      {
        print STDERR "Error: instructions in original and Diablo dumps are not equal\n";
        print STDERR "       Original: ", sprintf("%x", $address), " $origIns{$address}{opcode} $origIns{$address}{mnemonic} $origIns{$address}{operands}\n";
        print STDERR "       Diablo  : ", sprintf("%x", $address), " $diabloIns{$address}{opcode} $diabloIns{$address}{mnemonic} $diabloIns{$address}{operands}\n";
      }
    }
    else
    {
      print STDERR "Address ", sprintf("%x", $address), " found in original dump, but not in the Diablo dump", ;
      if (exists $diabloIns{($address)+1})
      {
        print STDERR " ... but ", sprintf("%x", ($address)+1), " does!";
      }
      elsif (exists $diabloIns{($address)-1})
      {
        print STDERR " ... but ", sprintf("%x", ($address)+1), " does!";
      }

      print STDERR "\n";
    }
  }
}
