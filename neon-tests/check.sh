#!/bin/sh

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <gcc or valgrind>"
  exit
fi

which ag &>/dev/null
if [ $? -ne 0 ]; then
  echo "Please install 'ag'"
  exit
fi

olddir="${PWD}"
cd "$1"

echo "Searching for fatal errors in Diablo output..."
ag -G diablo-output.txt -i "fatal" > diablo-fatals

echo "Searching for warnings in Diablo output..."
ag -G diablo-output.txt -i "warning" > diablo-warnings

echo "Searching for use/def errors in Diablo output..."
ag -G makefile-compare.txt -i "use/def" > diablo-objdump-usedef-errors

echo "Searching for mismatches between the Diablo output and the objdump output..."
ag -G makefile-compare.out -i "mismatch" > diablo-objdump-mismatches

cd "$olddir"
