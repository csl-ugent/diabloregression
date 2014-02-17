#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;

if (@ARGV != 2)
{
  print STDERR "Usage: $0 <original dump> <new dump>\n";
  exit 1;
}

sub readDump {
  # function arguments
  my $fileName = shift;
  # hash table by reference, to prevent copy
  my ($instrRef, $instrVal) = shift;
  my ($encRef, $encVal) = @_;

  # local variables
  my ($line, $lastLine, $header);

  open my $f, '<', $fileName or die "Error: failed to open dump file: $fileName ($!)\n";
  while(<$f>) {
    $lastLine = $line;
    $line = $_;

    # remove trailing NL
    chomp $line;

    # skip empty lines
    next if $line =~ m/^\s*$/;

    # skip header
    if (!(defined $header)) {
      if ($line =~ m/:\s+file format elf32-littlearm$/) {
        $header = 1;
        next;
      }

      die "Error: invalid header in dump at line $.: $line\n";
    }

    # skip section headers
    next if $line =~ m/^Disassembly of section/;

    # skip function/symbol names
    next if $line =~ m/^\s*[0-f]+ \<([^\>]+)\>:$/;

    # match instruction
    if ($line =~ m/^\s*([0-f]+):\s*([0-f]{4,8})\s+(.*?)(?:\s+;.*)?$/) {
      my $address     = hex($1);
      my $encoding    = hex($2);
      my $instruction = $3;

      $instruction =~ s/\s+/ /g;
      # remove trailing <...>
      $instruction =~ s/<[^>]+>$//;

      $instrRef->{$address} = $instruction;
      $encRef->{$address}   = $encoding;

    } elsif ($line =~ m/^\s*\.\.\.\s*$/) {
      print "Warning: ignoring repetition in dump at line $.: $lastLine\n";

    } else {
      print "Warning: unrecognized text in dump at line $.: $line\n";

    }
  }
}

sub diff_index {
  my ($a, $b) = @_;
  my $cmp = $a^$b;

  my @cmp;
  while ($cmp =~ /[^\0]/g) {
    # match non-zero byte
    push @cmp, pos($cmp)-1;
  }

  return @cmp;
}

sub printDifference {
  my $num1 = sprintf("%032b", shift);
  my $num2 = sprintf("%032b", @_);

  my @diff = diff_index($num1, $num2);
  my @diffarr;
  for my $i (0 .. 31) {
    # annotate different bits
    if ($i ~~ @diff) {
      push @diffarr,'x';
    } else {
      push @diffarr,'.';
    }
  }

  $num1 = join(' ', $num1 =~ m/.{4}/g);
  $num2 = join(' ', $num2 =~ m/.{4}/g);

  my $diffstr = join('', @diffarr);
  $diffstr = join(' ', $diffstr =~ m/.{4}/g);

  return sprintf("%s\n%s\n%s", $num1, $diffstr, $num2);
}

# command-line arguments
my $originalFile = $ARGV[0];
my $diabloFile   = $ARGV[1];

{
  print "Reading orginal objdump...\n";
  my %oldInstructions;
  my %oldEncodings;
  readDump($originalFile, \%oldInstructions, \%oldEncodings);

  print "Reading new objdump...\n";
  my %newInstructions;
  my %newEncodings;
  readDump($diabloFile, \%newInstructions, \%newEncodings);

  #print "Comparing old with new objdump, only looking at V* instructions\n";
  foreach my $oldAddress (keys %oldEncodings) {
    my $oldEncoding = $oldEncodings{$oldAddress};
    my $newEncoding = $newEncodings{$oldAddress};

    # skip nop's
    next if ($oldEncoding == 0xe320f000);
    
    if ($oldEncoding != $newEncoding) {
      my $oldEncHex = sprintf("%08x", $oldEncoding);
      my $oldAddrHex = sprintf("%08x", $oldAddress);
      my $newEncHex = sprintf("%08x", $newEncoding);
      my $diff = printDifference($oldEncoding, $newEncoding);

      print "Error: different encodings @ 0x$oldAddrHex: $oldEncHex -> $newEncHex\n$diff\n\n";
    }
  }
}
