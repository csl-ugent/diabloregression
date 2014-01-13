#!/bin/sh

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <valgrind source directory>"
  exit
fi

tests=("neon128" "neon64" "vfp" "vcvt_fixed_float_VFP")
scriptdir=$(dirname `realpath "$0"`)/../common
dir=$1/none/tests/arm

mkdir -p "tests"

counter=1
for test in "${tests[@]}"
do
  filename="$test"
  file="$test.c"
  directory="tests/$filename"

  mkdir -p "$directory"
  cp "$dir/$file" "$directory/"

  cat << EOF > $directory/Makefile
PROG=${filename}
EXTRA_CFLAGS=-Os

include $scriptdir/Makefile.in
EOF

  let counter=$counter+1
done

echo "Copied $counter tests from the GCC source tree"
