#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;

if (@ARGV != 3)
{
  print STDERR "Usage: $0 <original dump> <new dump> <diablo listing>\n";
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

sub readListing {
  my $fileName = shift;
  my ($addrRef, $addrVal) = @_;

  my $line;

  print "Warning: ignoring DATA instructions\n";

  open my $f, '<', $fileName or die "Error: failed to open list file: $fileName ($!)\n";
  while(<$f>) {
    $line = $_;

    chomp $line;

    if ($line =~ m/^New\s+0x([0-f]+)\s+Old\s+0x([0-f]+)\s+:\s+(.*)$/) {
      my $newAddress = hex($1);
      my $oldAddress = hex($2);
      my $instruction = $3;

      if ($instruction =~ m/^DATA/) {
        #print "Warning: ignoring data in list at line $.: $line\n";
      } else {
        $addrRef->{$oldAddress} = $newAddress;
      }
    } else {
      print "Warning: unrecognized text in list at line $.: $line\n";
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
my $listFile     = $ARGV[2];

{
  print "Reading orginal objdump...\n";
  my %oldInstructions;
  my %oldEncodings;
  readDump($originalFile, \%oldInstructions, \%oldEncodings);

  print "Reading new objdump...\n";
  my %newInstructions;
  my %newEncodings;
  readDump($diabloFile, \%newInstructions, \%newEncodings);

  print "Reading list file...\n";
  my %addressTranslations;
  readListing($listFile, \%addressTranslations);

  #print "Comparing old with new objdump, only looking at V* instructions\n";
  foreach my $oldAddress (keys %addressTranslations) {
    my $oldEncoding = $oldEncodings{$oldAddress};
    my $oldInstruction = $oldInstructions{$oldAddress};
    $oldInstruction =~ m/\s*([^\s]*)/;
    my $oldMnemonic = $1;

    my $newAddress = $addressTranslations{$oldAddress};
    my $newEncoding = $newEncodings{$newAddress};
    my $newInstruction = $newInstructions{$newAddress};
    $newInstruction =~ m/\s*([^\s]*)/;
    my $newMnemonic = $1;

    # skip movw/movt instructions
    next if (($newMnemonic =~ m/movw/i) or ($newMnemonic =~ m/movt/i));
    # skip load PC immetiate instructions
    next if ($oldEncoding & 0x0f7f0000)==0x051f0000;
    # skip load PC register instructions
    next if ($oldEncoding & 0x0e5f0000)==0x061f0000;

    #if ($newInstruction =~ m/^v/ or $oldInstruction =~ m/^v/)
    #if ($oldMnemonic != $newMnemonic)
    {
      if ($oldMnemonic eq $newMnemonic && $oldMnemonic=~m/^bl?/i) {
      } elsif ($newEncoding != $oldEncoding) {
        my $oldAddrHex = sprintf("%08x", $oldAddress);
        my $oldEncHex = sprintf("%08x", $oldEncoding);
        my $newAddrHex = sprintf("%08x", $newAddress);
        my $newEncHex = sprintf("%08x", $newEncoding);

        # maybe we are dealing with an VLDR/VSTR instruction relative to the PC...
        # for the time being, disable checking the immediate value.
        my $oldEncodingTest = $oldEncoding & 0x0f2f0e00;
        my $newEncodingTest = $newEncoding & 0x0f2f0e00;
        if(($oldEncodingTest == $newEncodingTest) and ($oldEncodingTest == 0x0d0f0a00)) {
          #print "Warning: ignoring immediate VLDR/VSTR instruction relative to the PC: $oldEncHex : $oldInstruction (address 0x$oldAddrHex -> 0x$newAddrHex)\n"

        } else {
          my $diff = printDifference($oldEncoding, $newEncoding);
          print "Error: difference - OLD: 0x$oldAddrHex 0x$oldEncHex '$oldInstruction'\tNEW: 0x$newAddrHex 0x$newEncHex '$newInstruction'\n$diff\n\n";

        }
      }
    }
  }
}
