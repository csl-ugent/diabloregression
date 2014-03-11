#!/usr/bin/perl -w

use strict;
use warnings;

require "functions.pm";

use Data::Dumper;
use File::Temp qw/ tempfile /;

if (@ARGV != 2)
{
  print STDERR "Usage: $0 <diabloarm_opcodes.c> <encoded instruction>\n";
  exit 1;
}

my $tableFile  = $ARGV[0];
unless (-e $tableFile) {
  print STDERR "Error: file $tableFile does not exist!\n";
  exit 1;
}

my $encodedStr = $ARGV[1];
my $encoded = hex($encodedStr);

my ($fh, $fn) = tempfile();
my $result = `gcc -fpreprocessed -dD -E "$tableFile" > "$fn"`;

################### READ DECODER TABLE
my @instructions = read_opcodes($fh);

################### TEST DECODER TABLE
{
  foreach my $aKey (0 .. $#instructions-1) {
    # iterate over each instruction, except the default catch-all handler
    my $aMask = hex($instructions[$aKey]{'mask'});
    my $aValue = hex($instructions[$aKey]{'value'});

    if (($encoded & $aMask) == $aValue) {
      print "Found instruction definition for encoding $encodedStr\n";
      print "  ",print_opcode(%{$instructions[$aKey]}),"\n";
      exit;
    }
  }

  print "No instruction definition found for encoding $encodedStr\n";
}
