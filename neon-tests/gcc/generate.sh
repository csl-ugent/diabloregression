#!/bin/sh

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <gcc source directory>"
  exit
fi

scriptdir=$(dirname `realpath "$0"`)/../common
dir=$1/gcc/testsuite/gcc.target/arm/neon

mkdir -p "tests"


counter=1
for file in `ls $dir/*.c`
do
  file=$(basename $file)

  filename="${file%.*}"
  directory="tests/$filename"

  mkdir -p "$directory"
  cp "$dir/$file" "$directory/"

  functionname=$(cat $directory/$file | grep -E '^void[[:blank:]]+[a-zA-Z0-9_]+[[:blank:]]*\([[:blank:]]*(void)?[[:blank:]]*\)' | tail -n1 | sed -r 's/\(\)$/ \(\)/' | sed -r 's/\s+/ /g' | cut -d ' ' -f 2)
  if [ -z "$functionname" ]; then
    echo "Error: empty test function name for $file"
    rm -rf "$directory"
  else
    cat << EOF >> $directory/$file

int main(int argc, const char ** argv) {
  $functionname();
  return 0;
}
EOF

    cat << EOF > $directory/Makefile
PROG=${filename}
EXTRA_CFLAGS=-O0

include $scriptdir/Makefile.in
EOF

  let counter=$counter+1
  fi
done

echo "Copied $counter tests from the GCC source tree"
