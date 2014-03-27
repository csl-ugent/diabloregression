#!/usr/bin/perl -w

use strict;
use warnings;

sub read_llvm_dump {
  my ($fh, $instructions) = @_;
  my $header;

  while (<$fh>) {
    # read line and remove trailing/leading whitespace
    my $line = $_;
    chomp $line;

    next if $line =~ m/^\s*$/;
    next if $line =~ m/^Disassembly of section/;
    next if $line =~ m/^\s*[0-f]+ \<([^\>]+)\>:$/;
    next if $line =~ m/^\S*:$/;

    if (!(defined $header)) {
      if ($line =~ m/:\s+file format ELF32-arm$/) {
        $header = 1;
        next;
      }

      die "Error: invalid header in dump at line $.: $line\n";
    }

    if ($line =~ m/^\s+([0-f]+):\s+((?:[0-f]{2}\s){2,4})\s+([^\s]+)(?:\s+(.*))?$/i)
    {
      my $address = $1;
      my $opcode = $2;
      my $mnemonic = $3;

      my $operands = "";
      if (defined $4)
      {
        $operands = $4;
      }

      # consider enianness in opcode
      my @bytes = split(' ', $opcode);
      for (my $i=0; $i < @bytes; $i+=2) {
        # exchange these bytes
        my $t = $bytes[$i];
        $bytes[$i] = $bytes[$i+1];
        $bytes[$i+1] = $t;
      }
      $opcode = join('', @bytes);

      $instructions->{$address} = {
        opcode => $opcode,
        mnemonic => $mnemonic,
        operands => $operands
      }
    }
    else
    {
      print STDERR "Warning: ignoring unrecognised line in file $.:$line\n";
    }
  }
}

1;
