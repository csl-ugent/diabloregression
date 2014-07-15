#!/usr/bin/perl -w

use strict;
use warnings;

use Carp;
use English;
use Data::Dumper;

require "objdump.pm";
require "diablo.pm";

sub NormalizeObjdumpOperands {
  my $ops = shift;

  $ops =~ s/pc/r15/g;
  $ops =~ s/sp/r13/g;
  $ops =~ s/^\s+//;
  $ops =~ s/\s+$//;
  $ops =~ s/,\s+/,/g;
  $ops =~ s/,#0\]/\]/g;

  return $ops;
}

sub NormalizeObjdumpMnemonic {
  my $mn = shift;

  $mn =~ s/\.n$//i;

  return $mn;
}

sub NormalizeDiabloOperands {
  my $ops = shift;

  $ops =~ s/pc/r15/g;
  $ops =~ s/,#0\]/\]/g;
  $ops =~ s/,\s+/,/g;

  while ($ops =~ m/([drs])([0-9]+)-\1([0-9]+)/)
  {
    my($regtype, $lbound, $ubound) = ($1, $2, $3);

    confess "Wtf" if $lbound > $ubound;

    my @regs;
    push @regs, "$regtype$ARG" foreach ($lbound .. $ubound);
    $ops = ${^PREMATCH} . (join ',', @regs) . ${^POSTMATCH};
  }

  return $ops;
}

if (@ARGV != 2)
{
  print STDERR "Usage: $0 <original objdump> <Diablo log>\n";
  exit 1;
}

my $origDump = $ARGV[0];
my $diabloLog = $ARGV[1];

my $rx_cc = qr/EQ|NE|CS|CC|MI|PL|VS|VC|HI|LS|GE|LT|GT|LE/i;

{
  print "Reading original dump: $origDump\n";
  my %origIns;
  open my $origFileHandle, '<', $origDump or die "Error: failed to open original dump file $origDump\n";
  read_dump($origFileHandle, \%origIns);
  close $origFileHandle;

  print "Reading Diablo log: $diabloLog\n";
  my %diabloIns;
  open my $diabloFileHandle, '<', $diabloLog or die "Error: failed to open Diablo log file $diabloLog\n";
  read_diablo_asmins($diabloFileHandle, \%diabloIns);
  close $diabloFileHandle;

  print "Comparing original objdump instructions with Diablo log instructions\n";
  my $nfailOP = 0;
  my $nfailMN = 0;
  my $nfailNE = 0;
  my $nsucc = 0;
  foreach my $address (keys %origIns)
  {
    my $saddress = sprintf("%x", $address);

    if (exists $diabloIns{$address})
    {
      my %di = %{$diabloIns{$address}};
      my $dm = $di{mnemonic};
      my $do = NormalizeDiabloOperands($di{operands});

      my %oi = %{$origIns{$address}};
      my $om = NormalizeObjdumpMnemonic($oi{mnemonic});
      my $oo = NormalizeObjdumpOperands($oi{operands});

      if ((($dm eq "add") and ($om eq "addw") and ($oo eq $do)) or
          (($dm eq "bl") and ($om eq "nop")) or
          ($om eq "ldfp") or ($om eq "stfp") or
          ($om eq "ldfe") or ($om eq "stfe"))
      {
        $nsucc++;
      }
      elsif (($dm eq $om) or
          (($dm =~ m/stm${rx_cc}?ia/) and ($om =~ m/stm${rx_cc}?/)) or
          (($dm =~ m/ldm${rx_cc}?ia/) and ($om =~ m/ldm${rx_cc}?/)) or
          (($dm eq "rsb.w") and ($om eq "rsb")) or
          (($dm eq "mvn") and ($om eq "mvn.w")) or
          (($dm eq "bic") and ($om eq "bic.w")) or
          (($dm eq "and") and ($om eq "and.w")) or
          (($dm eq "ands") and ($om eq "ands.w")) or
          (($dm eq "ldrsh") and ($om eq "ldrsh.w")))
      {
        if (($do eq $oo) or
              ($om =~ m/b()?(\.w)?/) or
              ($om eq "blx") or
              ($om eq "bl") or
              ($om eq "nop") or
              ($om eq "movw") or
              ($om eq "movt"))
        {
          # OK
          $nsucc++;
        }
        else
        {
          # Maybe the operands are not considered equal because the first
          # and second operand are equal. If this is the case, possibly
          # Diablo or objdump skip printing the second operand.
          # Let's take this into accound when comparing the operands...

          # Get the first operand
          $oo =~ m/^([^,]*),/;
          my $dotemp = $do;
          my $ootemp = $oo;

          if ((length($oo) != length($do)) and (defined $1))
          {
            if (length($oo) > length($do))
            {
              # Diablo operand string is too short
              $dotemp = "$1,$do";
            }
            else
            {
              # Objdump operand string is too short
              $ootemp = "$1,$oo";
            }
          }

          if ($dotemp eq $ootemp)
          {
            $nsucc++;
          }
          else
          {
            print STDERR "Instruction at $saddress differs (operands)\n";
            print STDERR "  Objdump: $om >$oo<\n";
            print STDERR "  Diablo : $dm >$do<\n";
            $nfailOP++;
          }
        }
      }
      elsif (($om eq ".word") and ($dm eq "data"))
      {
        $do =~ m/\|([0-f]{8})\|/;

        if (hex($oo) != hex($1))
        {
          print STDERR "Instruction at $saddress differs (data)\n";
          print STDERR "  Objdump: $om >$oo<\n";
          print STDERR "  Diablo : $dm $do >$1<\n";

          $nfailOP++;
        }
        else
        {
          $nsucc++;
        }
      }
      elsif (($om eq "nop") and ($dm eq "b")) { $nsucc++; }
      elsif (($om eq "svc") and ($dm eq "swi")) { $nsucc++; }
      else
      {
        print STDERR "Instruction at $saddress differs (mnemonic)\n";
        print STDERR "  Objdump: >$om< $oo\n";
        print STDERR "  Diablo : >$dm< $do\n";
        $nfailMN++;
      }
    }
    else
    {
      print STDERR "Address $saddress found in original dump, but not in the Diablo dump", ;
      if (exists $diabloIns{($address)+1})
      {
        print STDERR " ... but ", sprintf("%x", ($address)+1), " does!";
      }
      elsif (exists $diabloIns{($address)-1})
      {
        print STDERR " ... but ", sprintf("%x", ($address)-1), " does!";
      }

      print STDERR "\n";
      $nfailNE++;
    }
  }

  print STDERR "Failed instructions\n";
  print STDERR "  Operands : $nfailOP\n";
  print STDERR "  Mnemonic : $nfailMN\n";
  print STDERR "  Not found: $nfailNE\n";
  print STDERR " TOTAL: ", ($nfailNE+$nfailMN+$nfailOP),"\n";
  print STDERR "Succeeded instructions\n";
  print STDERR " TOTAL: $nsucc\n";
}
