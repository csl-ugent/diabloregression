#!/bin/bash

set -eu

# Script that just copies the input binary to "b.out"
# Assumes the binary is the last parameter, as with the regression.py script

DESTFILE=b.out
SRCDIR=.

while getopts O: opt; do
  case $opt in
    O) SRCDIR="$OPTARG"
     ;;
  esac
done

echo cp "$SRCDIR"/"${@: -1}" "$DESTFILE"
cp "$SRCDIR"/"${@: -1}" "$DESTFILE"
touch "$DESTFILE".list
