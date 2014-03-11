#!/usr/bin/perl -w

use strict;
use warnings;

require "functions.pm";

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

my @instructions = read_opcodes($fh);

my %dups;
while (my ($key, $value) = each @instructions) {
  my %opc = %{$value};
  my $mnemonic = $opc{mnemonic};
  push @{$dups{$mnemonic}}, $key;
}

while (my ($key, $value) = each %dups) {
  if (@$value > 1) {
    # ignore mnemonics that only occure once

    print "\nDuplicate mnemonic found: \"$key\"\n";
    my @list = @instructions[@$value];
    while (my ($k,$v) = each @list) {
      my %opc = %{$v};
      print "  ",print_value(%{$v})," - ",print_opcode(%{$v}),"\n";
    }
  }
}

# my @sorted = sort { lc($a->{mnemonic}) cmp lc($b->{mnemonic}) } @instructions;

# foreach my $key (0 .. $#sorted) {
#   print print_opcode(%{$sorted[$key]}),"\n";
# }
