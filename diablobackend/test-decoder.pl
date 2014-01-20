#!/usr/bin/perl -w

use strict;
use warnings;

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
my @instructions;
{
  my $line;
  my $linenr = 0;

  while (<$fh>)
  {
    # read next line, remove trailing NL
    $line = $_;
    chomp $line;
    $linenr++;

    # skip empty lines
    next if $line =~ m/^\s*$/;

    # valid line format: "<mnemonic to translate> <resulting mnemonic>"
    if ($line =~ m/^\s*\{0x([0-f]{8}),\s*0x([0-f]{8}),\s*"([^"]*)",\s*[^\}]*\},?.*$/i) {
      push @instructions, { mask => $1, value => $2, mnemonic => $3, line => $linenr };

    } elsif ($line =~ m/^# ([0-9]*)/) {
      $linenr = 0+$1-1;

    } else {
      print "Warning: unrecognized text in decoder table file at line $linenr: $line\n";

    }
  }

  close $fh;
}

################### TEST DECODER TABLE
{
  foreach my $aKey (0 .. $#instructions-1) {
    # iterate over each instruction
    my $aValue = hex($instructions[$aKey]{'value'});
    my $fKey;

    foreach my $bKey (0 .. $#instructions) {
      # find match for instructionA
      my $bMask = hex($instructions[$bKey]{'mask'});
      my $bValue = hex($instructions[$bKey]{'value'});

      if (($aValue & $bMask) == $bValue) {
        $fKey = $bKey;
        last;
      }
    }

    if ($fKey != $aKey) {
      print "Error: instruction decoding went wrong!\n";
      print "  Input: line $instructions[$aKey]{'line'} - {0x$instructions[$aKey]{'mask'}, 0x$instructions[$aKey]{'value'}, \"$instructions[$aKey]{'mnemonic'}\"}\n";
      print "  Found: line $instructions[$fKey]{'line'} - {0x$instructions[$fKey]{'mask'}, 0x$instructions[$fKey]{'value'}, \"$instructions[$fKey]{'mnemonic'}\"}\n";
    }
  }
}