#!/usr/bin/perl -w

use strict;
use warnings;

no warnings 'portable';  # Support for 64-bit ints required

use Data::Dumper;
use File::Basename;
use File::Spec;

# Sort an array of register names according to the ordering of Diablo.
# Diablo outputs the registers in the following order:
#   r0-r15, s0-s31, d16-d31
# This function also checks if each element in the array is a valid register name.
#    Argument 1: array, each element is one register
#    Returns   : sorted array
sub sortregs {
  return sort {
    # validate and get first register name
    my $aType = "";
    my $aNum  = "";
    if ($a !~ m/(?:([rds])([0-9]+))|(?:(c)(c|v|z|n))/) {
      die "Error: invalid register $a\n";
    }
    if (defined $1) {
      $aType = $1;
      $aNum = $2;
    } else {
      $aType = $3;
      $aNum = $4;
    }

    # validate and get second register name
    my $bType = "";
    my $bNum  = "";
    if ($b !~ m/(?:([rds])([0-9]+))|(?:(c)(c|v|z|n))/) {
      die "Error: invalid register $b\n";
    }
    if (defined $1) {
      $bType = $1;
      $bNum = $2;
    } else {
      $bType = $3;
      $bNum = $4;
    }

    # compare the two register names
    if ($aType eq $bType) {

      # both registers are of the same type
      if ($aType eq "c") {
        my $alphabet = "cvzn";
        return index($alphabet, $aType) <=> index($alphabet, $bType);

      } else {
        return 0+($aNum) <=> 0+($bNum);

      }

    } else {
      # both registers are of a different type
      my $alphabet = "rcsd";
      return index($alphabet, $aType) <=> index($alphabet, $bType);

    }
  } @_;
}

# Extract the unique elements from an array
#    Argument 1: array
#    Returns   : array with duplicates removed
sub uniq {
  my %h;
  return grep { !$h{$_}++ } @_
}

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

die "Fatal: support for 64-bit ints required\n" if ('' . hex('100000000')) ne '4294967296';

# =================================================================================================
# check arguments
if (@ARGV < 2 || @ARGV > 4)
{
  print STDERR "Usage: $0 <diablo trace> <objdump log> [skip] [objdump pre-UAL to UAL list]\n";
  exit 1;

}
my $path = dirname(File::Spec->rel2abs(__FILE__));

# save arguments, default to no line skipping
my $traceLogFile  = $ARGV[0];
my $dumpFile      = $ARGV[1];
my $skip          = @ARGV > 2 ? $ARGV[2] : 0;
#my $listFile      = @ARGV > 3 ? $ARGV[3] : "$path/preual-to-ual.list";
my $listFile = "$path/preual-to-ual.list";
my $defalsousefile = "$path/def-also-use.list";

# *************************************************************************************************
# READ THE PRE-UAL TO UAL TRANSLATION LIST
my %translations;
{
  my $line;

  open my $lf, '<', $listFile or die "Failed to open instruction mnemonic list file: $listFile ($!)\n";
  while (<$lf>)
  {
    # read next line, remove trailing NL
    $line = $_;
    chomp $line;

    # skip empty lines
    next if $line =~ m/^\s*$/;

    # valid line format: "<mnemonic to translate> <resulting mnemonic>"
    if ($line =~ m/^([^\s]*)\s+(.*)$/) {
      $translations{$1} = $2;

    } else {
      print "Warning: unrecognized text in list file at line $.: $line\n";

    }
  }
}

# *************************************************************************************************
# READ THE DEF-ALSO-USE LIST FILE
my @defalsouse;
{
  my $line;

  open my $lf, '<', $defalsousefile or die "Failed to open defined, also used list file: $defalsousefile ($!)\n";
  while (<$lf>)
  {
    $line = $_;
    chomp $line;
    next if $line =~ m/^\s*$/;
    push(@defalsouse, $line);
  }
}

# *************************************************************************************************
# READ THE OBJECT DUMP DISASSEMBLY FILE
my %instructions;
{
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
    if ($line =~ m/^\s*([0-f]+):\t[0-f]{4,8}\s+([^\s].*?)(?:\s+;.*)?$/)
    {
      my $address = hex($1);
      my $instruction = $2;

      # translate instruction mnemonic to the UAL variant
      $instruction =~ m/^([^\s]*)/;
      my $mnemonic = $1;
      if (exists $translations{$1}) {
        my $new_mnemonic = $translations{$1};
        $instruction =~ s/^[^\s]*/$new_mnemonic/;
      }

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
      $instructions{$address} = $instruction;
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
}

# *************************************************************************************************
# READ AND PARSE THE DIABLO TRACE LOG FILE
open my $tf, '<', $traceLogFile or die "Failed to open trace log file: $traceLogFile ($!)\n";
while (<$tf>)
{
  # if "current line number" < "skip line count", go to next line
  next if $. < $skip;

  # Remove trailing NL
  chomp;

  s/\\l\s//g;
  $_ = lc $_;

  # <debug>"whitespace"trace"whitespace"0xabc..."whitespace":"whitespace"
  if (m/^<debug>\s+trace\s+0x([0-f]+)\s+:\s+([^\|]*?)\s+\|\s+([^\|]*?)\s+\|\s+(.*)$/)
  {
    # instruction address as hexadecimal number
    # save remaining extracted values
    my $address = hex($1);
    my $instruction = $2;
    my $deflist = $3;
    my $uselist = $4;

    # instruction parsing
    $instruction =~ s/\s+/ /g;
    $instruction =~ s/\s*\:\s*/\:/g;
    $instruction =~ s/\[r([0-9]|1[0-3]),\#0\]/[r$1]/g;
    $instruction = normalizeInstruction($instruction);

    my $instructionNEW = $instruction;
    # replace vldmia r13!, with vpop
    $instructionNEW =~ s/^vpop/vldmia r13!,/;
    #   same for vpush
    $instructionNEW =~ s/^vpush/vstmdb r13!,/;
    $instructionNEW =~ /(^[^\s]*)\s+(.*)/;

    my $mnemonic = $1;
    my $operandi = $2;

    my $operandiexp = $operandi;
    # replace scalar values
    $operandiexp =~ s/\[[0-9]*\]//g;

    # remember position of first register
    # TODO: rekening houden met instructies die slechts 1 operand hebben
    if ($operandiexp =~ m/^\{/) {
      $operandiexp =~ s/\},/\},\|/;
    } else {
      $operandiexp =~ s/,/,\|/;
    }

    # normalize instruction: D-registers
    while ($operandiexp =~ m/(d([0-9]+))/g) {
      my $num = $2;

      if ($num <= 15) {
        $num = $num*2;
        my $next = $num+1;
        $operandiexp =~ s/$1(,|\}|$)/s$num,s$next$1/g;
      }
    }
    # normalize instruction: Q-registers
    while ($operandiexp =~ m/(q([0-9]+))/g) {
      my $num = $2;

      if ($num <= 7) {
        $num = $num*4;
        my $next1 = $num+1;
        my $next2 = $num+2;
        my $next3 = $num+3;
        $operandiexp =~ s/$1(,|\}|$)/s$num,s$next1,s$next2,s$next3$1/g;
      } else {
        $num = $num*2;
        my $next = $num+1;
        $operandiexp =~ s/$1(,|\}|$)/d$num,d$next$1/g;
      }
    }

    $deflist =~ s/,\s*/,/g;
    $uselist =~ s/,\s*/,/g;

    $operandiexp =~ s/,\s*/,/g;

    my $defs = "";
    my $uses = "";

    # split arguments in first argument and rest
    my $rx_reg = qr/[rds][0-9]+|fpscr|cpsr/;
    my $rx_regs = qr/(?:${rx_reg})(?:,${rx_reg})*/;
    my $rx_regwb = qr/${rx_reg}\!/;
    my $rx_list = qr/\{${rx_regs}\}/;
    my $rx_core = qr/r[0-9]+/;
    my $rx_double = qr/d[0-9]+/;
    my $rx_single = qr/s[0-9]+/;
    my $rx_align = qr/\:\s*([0-9]+)\s*/;
    my $rx_cond = qr/cc|cv|cz|cn/;

    my @r = $deflist =~ m/(${rx_reg}|${rx_cond})/g;
    $deflist = join(',', @r);
    @r = $uselist =~ m/(${rx_reg})/g;
    $uselist = join(',', @r);

    $operandiexp =~ /^(?:(${rx_regs})|(${rx_regwb})|\{(${rx_regs})\}),\|\s*(.*)$/;


    my $dest = "";
    if (defined $1) {
      $dest = $1;
    } elsif (defined $2) {
      $dest = $2;
    } elsif (defined $3) {
      $dest = $3;
    } else {
      die "Error: invalid destination register: $instruction\n";
    }


    my $src = join(',', $4 =~ m/${rx_reg}/g);

    # diablo does not represent the CPSR directly in its def/use sets
    $dest =~ s/cpsr/cc,cv,cz,cn/g;

    my $alignDiablo  = "";
    my $alignObjdump = "";

    if ($mnemonic =~ m/^vld[0-9]/) {
      $defs = $dest;
      $uses = $src;

      $operandiexp =~ /${rx_align}\]/;
      $alignDiablo = $1 if (defined $1);
      $instructions{$address} =~ /${rx_align}\]/;
      $alignObjdump = $1 if (defined $1);

      my $op = $operandiexp;
      $op =~ s/\[|\]//g;

      # add wrote-back registers to defs
      my $wbregs = join(',',$op =~ /${rx_reg}\!/g);
      if ($wbregs ne "") {
        # remove bangs
        $wbregs =~ s/\!//g;
        $defs = "$wbregs,$defs";
      }

    } elsif ($mnemonic =~ m/^vst[0-9]/) {
      $uses = "$dest,$src";

      $operandiexp =~ /${rx_align}\]/;
      $alignDiablo = $1 if (defined $1);
      $instructions{$address} =~ /${rx_align}\]/;
      $alignObjdump = $1 if (defined $1);

      my $op = $operandiexp;
      $op =~ s/\[|\]//g;

      # add wrote-back registers to defs
      my $wbregs = join(',',$op =~ /${rx_reg}\!/g);
      if ($wbregs ne "") {
        # remove bangs
        $wbregs =~ s/\!//g;
        $defs = "$wbregs";
      }

    } elsif ($mnemonic =~ m/^vldm/) {
      $defs = $src;

      $dest =~ /(${rx_reg})(\!)?/;
      $uses = $1;
      if (defined $2) {
        # writeback
        $defs = "$1,$defs";
      }

    } elsif ($mnemonic =~ m/^vst/) {
      # regs
      my @regs = $operandiexp =~ m/([rds][0-9]+)/g;
      $uses = join(',', @regs);

      if ($operandiexp =~ m/^(r[0-9]+)\!/) {
        # writeback of first register
        $defs = $1;
      }

    } else {
      $defs = $dest;
      $uses = $src;

      # check if dest is also used
      $mnemonic =~ /^([^\.]*)/;
      if ($1 ~~ @defalsouse) {
        $uses = "$defs,$uses";
      }

      if ($mnemonic =~ m/^vmov/) {
        if ($operandi =~ m/^${rx_core},${rx_core},(?:${rx_double}|(${rx_single},${rx_single}))$/) {
          # mov rX, rY, dZ
          my @ops = $operandiexp =~ /${rx_reg}/g;

          $defs = "$ops[0],$ops[1]";
          $uses = join(',',@ops[2 .. $#ops]);
        } elsif ($operandi =~ m/^${rx_single},${rx_single},${rx_core},${rx_core}$/) {
          # mov sX, sY, rA, rB
          my @ops = $operandiexp =~ /${rx_reg}/g;

          $defs = "$ops[0],$ops[1]";
          $uses = join(',',@ops[2 .. $#ops]);
        }
      }

      $defs =~ s/,$//;
      $uses =~ s/,$//;
    }

    if($mnemonic =~ m/^vstr|vldr/) {
      $instruction =~ s/,#0\]/\]/g;
    }

    if ($alignDiablo ne $alignObjdump) {
      die "Error: alignment fields not equal\n";
    }

    $defs = join(',', sortregs(uniq(split(',',$defs))));
    $uses = join(',', sortregs(uniq(split(',',$uses))));

    if (($uselist ne $uses) or ($deflist ne $defs)) {
print <<END;
Instruction: >$instruction<
Expanded operandi: >$operandiexp<
Diablo-defs: >$deflist<
Diablo-uses: >$uselist<
Defs       : >$defs<
Uses       : >$uses<
END
      die "Use/Def register sets incorrect on Diablo line $.\n";
    }

    if (defined $instructions{$address})
    {
      if ($instructions{$address} ne $instruction)
      {
        print "Error: mismatch on Diablo dump line $.: '$instruction' vs. '$instructions{$address}'\n";
      } else {
        #print "$instruction\n";
      }
    }
    else
    {
      print "Error: assembly dump does not contain an instruction at address $address (Diablo dump line $.: $instruction)\n";
    }
  }
  else
  {
    print "Warning: unrecognized text in trace log: $_\n";
  }
}
close $tf;
