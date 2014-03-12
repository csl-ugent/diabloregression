#!/usr/bin/perl -w

use strict;
use warnings;

sub read_dump {
  my ($fh) = @_;

  my %instructions

  while (<$fh>) {
    # read line and remove trailing/leading whitespace
    $line = $_;
    chomp $line;
  }

  %instructions;
}

1;
