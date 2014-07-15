#!/usr/bin/perl -w

use strict;
use warnings;

require "objdump.pm";

sub read_diablo_listing {
  my ($fh, $instructions) = @_;

  my $line;

  print "Warning: ignoring DATA instructions\n";

  while(<$fh>) {
    $line = $_;

    chomp $line;

    if ($line =~ m/^New\s+0x([0-f]+)\s+Old\s+0x([0-f]+)\s+:\s+(.*)$/) {
      my $newAddress = hex($1);
      my $oldAddress = hex($2);
      my $instruction = $3;

      if ($instruction =~ m/^DATA/) {
        #print "Warning: ignoring data in list at line $.: $line\n";
      } else {
        $instructions->{$oldAddress} = $newAddress;
      }
    } else {
      print "Warning: unrecognized text in list at line $.: $line\n";
    }
  }
}

sub read_diablo_asmins {
  my ($fh, $instructions) = @_;
  my ($dumpHeader, $lastLine, $line);

  while (<$fh>)
  {
    $lastLine = $line;
    $line = $_;

    # Remove trailing NL
    chomp $line;

    # Skip empty lines
    next if $line =~ m/^\s*$/;

    # valid lines: <hex address>: <hex opcode> <instruction> ; <data>
    #   we discard the "<data>"-part
    if ($line =~ m/^\s*assemble 0x([0-f]+)\s*:\s*(?:T\s+)?([^\s]+)(?:\s+(.*))?$/)
    {
      my $address = $1;
      my $mnemonic = $2;

      my $operands = "";
      if (defined $3)
      {
        $operands = $3;
      }

      $instructions->{hex($address)} = {
        mnemonic => lc $mnemonic,
        operands => normalizeInstruction(lc $operands)
      };
    #   my $address = $1;
    #   my $opcode = $2;
    #   my $instruction = $3;

    #   # replace all multiple whitespace characters with ONE space
    #   $instruction =~ s/\s+/ /g;
    #   $instruction =~ s/\s*\:\s*/\:/g;
    #   # remove trailing <...>
    #   $instruction =~ s/<[^>]+>$//;
    #   # replace vldmia r13!, with vpop
    #   $instruction =~ s/^vldmia r13!,/vpop/;
    #   #   same for vpush
    #   $instruction =~ s/^vstmdb r13!,/vpush/;
    #   $instruction =~ s/APSR_nzcv/cpsr/g;

    #   $instruction = normalizeInstruction($instruction);

    #   $instruction =~ m/([^\s]+)(?:\s+(.*))?$/;
    #   my $mnemonic = $1;
    #   my $operands = "";
    #   if (defined $2)
    #   {
    #     $operands = $2;
    #   }

    #   # {"d OR r OR s""decimal 1 or more""do not group-match optional '[]'"-"first matched character; backreference""decimal, 1 or more""if first reg also '[]', match '[]' here too"}
    #   if ($instruction =~ m/\{([drs])([0-9]+)((?:\[\])?)-\1([0-9]+)\3\}/p)
    #   {
    #     my $registerType = $1;
    #     my $start = $2;
    #     my $dScalar = $3;
    #     my $end = $4;
    #     if (($registerType ne 'd' and $dScalar ne ''))
    #     #if (($end <= $start) or ($registerType ne 'd' and $dScalar ne ''))
    #     {
    #       die "Error: invalid register list in assembly dump at line $.: $line\n";
    #     }
    #     $instruction = "${^PREMATCH}\{${registerType}" . (join "$dScalar,$registerType", ($start .. $end)) . "$dScalar\}${^POSTMATCH}";
    #   }

    #   $opcode =~ s/\s//g;

    #   #print "Adding instruction 0x$address $mnemonic $operands\n";
    #   $instructions->{hex($address)} = {
    #     opcode => $opcode,
    #     mnemonic => $mnemonic,
    #     operands => $operands
    #   };
    # }
    # elsif ($line =~ m/^\s+\.\.\.\s*$/)
    # {
    #   print "Warning: ignoring repetition in assembly dump at line $.: $lastLine\n";
    # }
    # else
    # {
    #   print "Warning: unrecognized text in assembly dump: $line\n";
    }
  }
}

1;
