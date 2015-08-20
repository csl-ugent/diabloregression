#!/bin/bash

function print_help_exit {
  cat <<EOF
$0
    -c <toolchain id>                       (required) The unique ID of the benchmark set to be installed (see below).

    One of the following two parameters should be specified, -T dominates -t:
    -t <toolchain destination directory>    (optional) Specific toolchain installation directory.
    -T <toolchain base directory>           (optional) Generic toolchain installation directory.
                                                        Based on the toolchain to be installed, an appropriate directory
                                                        is created herein, in a predetermined directory structure.

    -h                                      (optional) Print this help message and exit.

These are the Diablo-compatible toolchains:

Linux
   ARM
      1. GCC 4.6.4
      2. GCC 4.6.4 (hardfloat); not available yet
      3. GCC 4.8.1
      4. GCC 4.8.1 (hardfloat)

   Thumb
      5. GCC 4.6.4
      6. GCC 4.6.4 (hardfloat); not available yet
      7. GCC 4.8.1
      8. GCC 4.8.1 (hardfloat)

   i486
      9. GCC 4.6.4
     10. GCC 4.8.1

   LLVM
     11. LLVM 3.2
     12. LLVM 3.3
     13. LLVM 3.4
     14. LLVM 3.5
     15. LLVM 3.6

Android
   ARM/Thumb
     16. GCC 4.6
     17. GCC 4.8

   LLVM
     18. LLVM 3.3
     19. LLVM 3.4

Android (64-bit); these toolchains are only meant to build the AOSP sources
     20. GCC 4.6
     21. GCC 4.8

EOF
  exit 1
}

toolchain_directory=
toolchain_base_directory=
toolchain_id=

while getopts "c:t:T:h" opt; do
  case $opt in
    c) toolchain_id="$OPTARG"
        ;;
    t) toolchain_directory="$OPTARG"
        ;;
    T) toolchain_base_directory="$OPTARG"
        ;;
    h) print_help_exit
        ;;
  esac
done

. $(cd `dirname $0` && pwd)/configuration.sh

TOOLCHAIN[1]="linux/gcc/arm/gcc-4.6.4"
TOOLCHAIN[2]="linux/gcc/arm/gcc-4.6.4_hard"
TOOLCHAIN[3]="linux/gcc/arm/gcc-4.8.1"
TOOLCHAIN[4]="linux/gcc/arm/gcc-4.8.1_hard"
TOOLCHAIN[5]="linux/gcc/thumb/gcc-4.6.4"
TOOLCHAIN[6]="linux/gcc/thumb/gcc-4.6.4_hard"
TOOLCHAIN[7]="linux/gcc/thumb/gcc-4.8.1"
TOOLCHAIN[8]="linux/gcc/thumb/gcc-4.8.1_hard"
TOOLCHAIN[9]="linux/gcc/i486/gcc-4.6.4"
TOOLCHAIN[10]="linux/gcc/i486/gcc-4.8.1"
TOOLCHAIN[11]="linux/llvm/llvm-3.2"
TOOLCHAIN[12]="linux/llvm/llvm-3.3"
TOOLCHAIN[13]="linux/llvm/llvm-3.4"
TOOLCHAIN[14]="linux/llvm/llvm-3.5"
TOOLCHAIN[15]="linux/llvm/llvm-3.6"
TOOLCHAIN[16]="android/gcc/thumb/gcc-4.6"
TOOLCHAIN[17]="android/gcc/thumb/gcc-4.8"
TOOLCHAIN[18]="android/llvm/llvm-3.3"
TOOLCHAIN[19]="android/llvm/llvm-3.4"
TOOLCHAIN[20]="android/gcc/thumb/gcc-4.6_64bit"
TOOLCHAIN[21]="android/gcc/thumb/gcc-4.8_64bit"

# Parameters
#  1. toolchain archive file
#  2. installation path
function install_toolchain {
  tc_archive=`rel_to_abs_file $1`
  tc_destination="$2"

  # extract the data
  create_dir_empty "${tc_destination}"

  tc_absolute=`cd $tc_destination && pwd`
  cd ${tc_destination}

  tar xf ${tc_archive}

  for f in `grep -lr "DIABLO_TOOLCHAIN_PATH" .`
  do
    # only process text files
    if [ -n "`file $f | grep text`" ]; then
      echo "Patching file $f"

      sed -i "s:DIABLO_TOOLCHAIN_PATH:${tc_absolute}:g" $f
    fi
  done

  cd - > /dev/null
}

function get_toolchain_directory {
  if [ -z "$toolchain_base_directory" ]; then
    echo "$toolchain_directory"
  else
    echo "$toolchain_base_directory/$1"
  fi
}

if [ -z "$toolchain_directory" ] && [ -z "$toolchain_base_directory" ]; then
  echo "please specify either the base toolchain directory or a specific one"
  print_help_exit
fi

check_empty "$toolchain_id" "please provide the ID of the toolchain to be installed"

tc_path=${TOOLCHAIN["$toolchain_id"]}
tc_destination=`get_toolchain_directory $tc_path`

tc_archive=/mnt/data/toolchains/${tc_path}.tar.bz2

tmp_file=`make_temp_suffix .tar.bz2`
download $tc_archive $tmp_file

echo "installing to $tc_destination"
install_toolchain $tmp_file $tc_destination

rm $tmp_file
