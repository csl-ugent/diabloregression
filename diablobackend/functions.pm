#!/usr/bin/perl -w

use strict;
use warnings;

sub read_opcodes {
  my ($fh) = @_;

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
      if ($line =~ m/^\s*\{0x([0-f]{8}),\s*0x([0-f]{8}),\s*"([^"]*)",\s*([^\}]*)\},?.*$/i) {
        my $mask = $1;
        my $value = $2;
        my $mnemonic = $3;
        my $handler = $4;

        if (($mnemonic =~ m/^f/i) and ($handler =~ m/vfp/i) and !($mnemonic =~ m/fstmx|fldmx/i)) {
          print "Warning: ignoring deprecated floating-point instruction at line $linenr: $line\n";

        }
        else
        {
          push @instructions, { mask => $mask, value => $value, mnemonic => $mnemonic, line => $linenr };

        }

      } elsif ($line =~ m/^# ([0-9]*)/) {
        $linenr = 0+$1-1;

      } else {
        print "Warning: unrecognized text in decoder table file at line $linenr: $line\n";

      }
    }

    close $fh;
  }

  @instructions;
}

sub print_opcode {
  my (%opc) = @_;
  return "line $opc{'line'} - {0x$opc{'mask'}, 0x$opc{'value'}, \"$opc{'mnemonic'}\"}";
}

sub print_value {
  my (%opc) = @_;

  my $mstring = sprintf("%032b", hex($opc{mask}));
  my @marray  = split("", $mstring);

  my $vstring = sprintf("%032b", hex($opc{value}));
  my @varray  = split("", $vstring);

  my $str = "";
  while (my ($idx, $mbit) = each @marray) {
    if ($mbit eq "1") {
      $str = sprintf("%s%s", $str, $varray[$idx]);
    } else {
      $str = sprintf("%s.", $str);
    }
  }

  $str = join(' ', $str =~ m/.{4}/g);

  $str;
}

1;
