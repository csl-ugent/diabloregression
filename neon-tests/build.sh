#!/bin/sh

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <testcases (gcc or valgrind)> <path to Diablo binary (diablo-arm)> <path to Diablo source> <path to toolchain>"
  exit
fi

startdir="${PWD}"
cd "$1"

export SCRIPTS="${PWD}/../common/"
export DIABLO=`realpath $2`
export DIABLOSOURCE=`realpath $3`
export TOOLCHAIN=`realpath $4`

for i in `ls -d tests/*/`
do
  olddir="${PWD}"

  cd $i
  make clean
  make all > makefile-all.out
  make dump > makefile-dump.out
  make test > makefile-test.out
  make compare > makefile-compare.out
  cd "$olddir"
done

cd "$startdir"
