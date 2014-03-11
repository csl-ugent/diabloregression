#!/usr/bin/perl -w

use strict;
use warnings;

require "functions.pm";

use Data::Dumper;
use File::Temp qw/ tempfile /;

if (@ARGV != 2)
{
  print STDERR "Usage: $0 <diabloarm_opcodes.c> <key>\n";
  exit 1;
}

my $tableFile  = $ARGV[0];
unless (-e $tableFile) {
  print STDERR "Error: file $tableFile does not exist!\n";
  exit 1;
}

my $key = $ARGV[1];

my ($fh, $fn) = tempfile();
my $result = `gcc -fpreprocessed -dD -E "$tableFile" > "$fn"`;

################### READ DECODER TABLE
my @instructions = read_opcodes($fh);

################### TEST DECODER TABLE
print "Opcode: ",print_opcode(%{$instructions[$key]}),"\n";
