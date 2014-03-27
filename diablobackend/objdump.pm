#!/usr/bin/perl -w

use strict;
use warnings;

# Normalize an instruction
sub normalizeInstruction($)
{
  my $instruction = shift;

  # Trim spaces
  $instruction =~ s/([,\[\]])\s+([,\[\]\#\{drs])/$1$2/g;

  # Unhex
  if ($instruction =~ m/0x/)
  {
    while ($instruction =~ m/([,\#\[])(-?)0x([0-f]+)([,\#\]])/p or $instruction =~ m/([,\#\[])(-?)0x([0-f]+)$/p)
    {
      my $trail = '';
      $trail = $4 if defined $4;
      $instruction = "${^PREMATCH}$1$2" . hex($3) . "${trail}${^POSTMATCH}";
    }
  }

  return $instruction;
}

sub read_objdump {
  my %instructions;

  my ($dumpFile) = @_;
  my ($dumpHeader, $lastLine, $line);

  open my $df, '<', $dumpFile or die "Failed to open assembly dump file: $dumpFile ($!)\n";
  while (<$df>)
  {
    $lastLine = $line;
    $line = $_;

    # Remove trailing NL
    chomp $line;

    # Skip empty lines
    next if $line =~ m/^\s*$/;

    # Skip header
    if (!(defined $dumpHeader))
    {
      if ($line =~ m/:\s+file format elf32-littlearm$/)
      {
        $dumpHeader = 1;
        next;
      }
      die "Error: invalid header in assembly dump: $_\n";
    }

    # Skip section headers
    next if $line =~ m/^Disassembly of section/;

    # Skip function/symbol names
    next if $line =~ m/^\s*[0-f]+ \<([^\>]+)\>:$/;

    # valid lines: <hex address>: <hex opcode> <instruction> ; <data>
    #   we discard the "<data>"-part
    if ($line =~ m/^\s*([0-f]+):\t([0-f]{4}\s+[0-f]{4}|[0-f]{4,8})\s+([^\s].*?)(?:\s+;.*)?$/)
    {
      my $address = hex($1);
      my $opcode = $2;
      my $instruction = $3;

      # replace all multiple whitespace characters with ONE space
      $instruction =~ s/\s+/ /g;
      $instruction =~ s/\s*\:\s*/\:/g;
      # remove trailing <...>
      $instruction =~ s/<[^>]+>$//;
      # replace vldmia r13!, with vpop
      $instruction =~ s/^vldmia r13!,/vpop/;
      #   same for vpush
      $instruction =~ s/^vstmdb r13!,/vpush/;
      $instruction =~ s/APSR_nzcv/cpsr/g;

      $instruction = normalizeInstruction($instruction);

      # {"d OR r OR s""decimal 1 or more""do not group-match optional '[]'"-"first matched character; backreference""decimal, 1 or more""if first reg also '[]', match '[]' here too"}
      if ($instruction =~ m/\{([drs])([0-9]+)((?:\[\])?)-\1([0-9]+)\3\}/p)
      {
        my $registerType = $1;
        my $start = $2;
        my $dScalar = $3;
        my $end = $4;
        if (($end <= $start) or ($registerType ne 'd' and $dScalar ne ''))
        {
          die "Error: invalid register list in assembly dump at line $.: $line\n";
        }
        $instruction = "${^PREMATCH}\{${registerType}" . (join "$dScalar,$registerType", ($start .. $end)) . "$dScalar\}${^POSTMATCH}";
      }

      $instructions{$address} = {
        opcode => $opcode,
        instruction => $instruction
      };
    }
    elsif ($line =~ m/^\s+\.\.\.\s*$/)
    {
      print "Warning: ignoring repetition in assembly dump at line $.: $lastLine\n";
    }
    else
    {
      print "Warning: unrecognized text in assembly dump: $line\n";
    }
  }
  close $df;

  %instructions;
}

# NEWER VERSION
sub read_dump {
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

    # Skip header
    if (!(defined $dumpHeader))
    {
      if ($line =~ m/:\s+file format elf32-littlearm$/)
      {
        $dumpHeader = 1;
        next;
      }
      die "Error: invalid header in assembly dump: $_\n";
    }

    # Skip section headers
    next if $line =~ m/^Disassembly of section/;

    # Skip function/symbol names
    next if $line =~ m/^\s*[0-f]+ \<([^\>]+)\>:$/;

    # valid lines: <hex address>: <hex opcode> <instruction> ; <data>
    #   we discard the "<data>"-part
    if ($line =~ m/^\s*([0-f]+):\t([0-f]{4}\s+[0-f]{4}|[0-f]{4,8})\s+([^\s].*?)(?:\s+;.*)?$/)
    {
      my $address = $1;
      my $opcode = $2;
      my $instruction = $3;

      # replace all multiple whitespace characters with ONE space
      $instruction =~ s/\s+/ /g;
      $instruction =~ s/\s*\:\s*/\:/g;
      # remove trailing <...>
      $instruction =~ s/<[^>]+>$//;
      # replace vldmia r13!, with vpop
      $instruction =~ s/^vldmia r13!,/vpop/;
      #   same for vpush
      $instruction =~ s/^vstmdb r13!,/vpush/;
      $instruction =~ s/APSR_nzcv/cpsr/g;

      $instruction = normalizeInstruction($instruction);

      $instruction =~ m/([^\s]+)(?:\s+(.*))?$/;
      my $mnemonic = $1;
      my $operands = "";
      if (defined $2)
      {
        $operands = $2;
      }

      # {"d OR r OR s""decimal 1 or more""do not group-match optional '[]'"-"first matched character; backreference""decimal, 1 or more""if first reg also '[]', match '[]' here too"}
      if ($instruction =~ m/\{([drs])([0-9]+)((?:\[\])?)-\1([0-9]+)\3\}/p)
      {
        my $registerType = $1;
        my $start = $2;
        my $dScalar = $3;
        my $end = $4;
        if (($registerType ne 'd' and $dScalar ne ''))
        #if (($end <= $start) or ($registerType ne 'd' and $dScalar ne ''))
        {
          die "Error: invalid register list in assembly dump at line $.: $line\n";
        }
        $instruction = "${^PREMATCH}\{${registerType}" . (join "$dScalar,$registerType", ($start .. $end)) . "$dScalar\}${^POSTMATCH}";
      }

      $opcode =~ s/\s//g;

      #print "Adding instruction 0x$address $mnemonic $operands\n";
      $instructions->{hex($address)} = {
        opcode => $opcode,
        mnemonic => $mnemonic,
        operands => $operands
      };
    }
    elsif ($line =~ m/^\s+\.\.\.\s*$/)
    {
      print "Warning: ignoring repetition in assembly dump at line $.: $lastLine\n";
    }
    else
    {
      print "Warning: unrecognized text in assembly dump: $line\n";
    }
  }
}

1;
