#!/usr/bin/perl -w

use strict;
use warnings;

require "functions.pm";

use Data::Dumper;
use File::Temp qw/ tempfile /;

if (@ARGV != 1)
{
  print STDERR "Usage: $0 <diabloarm_opcodes.c>\n";
  exit 1;
}

my $tableFile  = $ARGV[0];
unless (-e $tableFile) {
  print STDERR "Error: file $tableFile does not exist!\n";
  exit 1;
}

my ($fh, $fn) = tempfile();
my $result = `gcc -fpreprocessed -dD -E "$tableFile" > "$fn"`;

################### READ DECODER TABLE
my @instructions = read_opcodes($fh);

################### TEST DECODER TABLE
{
  foreach my $aKey (0 .. $#instructions-1) {
    # iterate over each instruction, except the default catch-all handler
    my $aValue = hex($instructions[$aKey]{'value'});
    my $fKey;

    foreach my $bKey (0 .. $#instructions) {
      # find match for the instruction-under-test
      my $bMask = hex($instructions[$bKey]{'mask'});
      my $bValue = hex($instructions[$bKey]{'value'});

      if (($aValue & $bMask) == $bValue) {
        $fKey = $bKey;
        last;
      }
    }

    if ($fKey != $aKey) {
      print "Error: instruction decoding went wrong!\n";
      print "  Input: ",print_opcode(%{$instructions[$aKey]}),"\n";
      print "  Found: ",print_opcode(%{$instructions[$fKey]}),"\n";
    }
  }
}