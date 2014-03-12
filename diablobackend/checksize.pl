#!/usr/bin/perl -w

use strict;
use warnings;

require "objdump.pm";

if (@ARGV != 2)
{
  print STDERR "Usage: $0 <Diablo log file> <original disassembly dump file>\n";
  exit 1;
}

my $logfile = $ARGV[0];
my $dumpfile = $ARGV[1];

print "Begin reading object dump $dumpfile\n";
my %objdump = read_objdump($dumpfile);
print "Done reading object dump $dumpfile\n";

my %csizes;
{
  my $line;

  open my $f, '<', $logfile or die "Failed to open Diablo log file: $logfile ($!)\n";
  while (<$f>)
  {
    $line = $_;
    chomp $line;

    next if $line =~ m/^\s*$/;

    if ($line =~ m/^<debug>\s+csize\s+0x([0-f]+)\s+:[^:]+\s*:\s*([0-9]+)$/i) {
      my $address = hex($1);
      my $csize = hex($2);

      if (exists $objdump{$address}) {
        my $opcode = $objdump{$address}{opcode};

        if (($csize == 2) and ($opcode =~ m/^[0-f]{4}$/)) {
          # ok
        } elsif (($csize == 4) and ($opcode =~ m/^[0-f]{4}\s[0-f]{4}$/)) {
          # ok
        } else {
          print STDERR "Error: ", sprintf("%x", $address), " - Diablo detects a $csize instruction, while in dump: $opcode\n";
        }

      } else {
        print STDERR "Error: ", sprintf("%x", $address), " ($csize) does not exist in original dump\n";
      }
    } else {
      #print "Warning: ignoring unrecognised text $logfile:$. - $line\n";
    }
  }
}