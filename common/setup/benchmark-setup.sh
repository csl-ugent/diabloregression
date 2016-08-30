#!/bin/bash

function print_help_exit {
  cat <<EOF
$0
    -c <configuration id>                       (required) The unique ID of the benchmark set to be installed (see below).
    -s <spec installation directory>            (required) The speec installation directory.
    -i <test system id>                         (required) The board id for which the benchmarks should be configured.
                                                            The possible values are defined in the configuration.sh file.

    One of the following two parameters should be specified, -B dominates -b:
    -b <benchmark destination directory>        (optional) Specific benchmark installation directory.
                                                            Only to be used when installing one benchmark series.
    -B <benchmark base destination directory>   (optional) Generic benchmark installation directory.
                                                            Based on the benchmark series to be installed, an appropriate directory
                                                            is created herein, in a predetermined directory structure.

    One of the following two parameters should be specified, -T dominates -t:
    -t <GCC toolchain directory>                (optional) Specific GCC toolchain directory.
                                                            Manual specification of the GCC toolchain root directory.
    -T <GCC toolchain base directory>           (optional) Generic GCC toolchain directory.
                                                            Based on the benchmark series to be installed, an appropriate GCC toolchain
                                                            is assumed to be present, in a predetermined directory structure.

    One of the following two parameters should be specified, -U dominates -u:
    -u <LLVM toolchain directory>               (optional) Specific LLVM toolchain directory.
                                                            Manual specification of the LLVM toolchain root directory.
    -U <LLVM toolchain base directory>          (optional) Generic LLVM toolchain directory.
                                                            Based on the benchmark series to be installed, an appropriate LLVM toolchain
                                                            is assumed to be present, in a predetermined directory structure.
                                                            If this parameter is omitted, and the "-u" parameter is also omitted, the same
                                                            base directory as passed with "-T" is assumed.

    The directory on the target system, -R dominates -r (if none is specified, '.' is assumed):
    -r <remote directory>                       (optional) Specific remote execution directory.
                                                            The same directory will be configured for every benchmark series.
    -R <remote base directory>                  (optional) Generic remote execution base directory.
                                                            An appropriate directory will be determined for every benchmark series.

    -o <optimisation level>                     (optional) Benchmark series optimisation level (0, 1, 2, 3 or s).
                                                            Multiple levels can be specified by using this parameter several times.
                                                            If this parameter is omitted, all optimisation levels will be installed.
    -l <link method>                            (optional) Benchmark series link method (static, dynamic or dynamic-pie)
                                                            Multiple levels can be specified by using this parameter several times.
                                                            If this parameter is omitted, all link methods will be installed.
    -h                                          (optional) Print this help message and exit.

These are the available benchmark sets.
Every set is available in static, dynamic and dynamic-pie linked configurations.
For every configuration, compiler optimisations O0, O1, O2, O3 and Os are available.

Linux
   ARM
      1. GCC 4.6.4
      2. GCC 4.8.1
      3. LLVM 3.2
      4. LLVM 3.3
      5. LLVM 3.4
      6. LLVM 3.5
      7. LLVM 3.6

   Thumb
      8. GCC 4.6.4
      9. GCC 4.8.1
     10. LLVM 3.2
     11. LLVM 3.3
     12. LLVM 3.4
     13. LLVM 3.5
     14. LLVM 3.6

   i486
     15. GCC 4.6.4
     16. GCC 4.8.1
     17. LLVM 3.2
     18. LLVM 3.3
     19. LLVM 3.4
     20. LLVM 3.5
     21. LLVM 3.6

   aarch64
     30. GCC 4.8.1

Android
   ARM
     22. GCC 4.6
     23. GCC 4.8
     24. LLVM 3.3
     25. LLVM 3.4

   Thumb
     26. GCC 4.6
     27. GCC 4.8
     28. LLVM 3.3
     29. LLVM 3.4
EOF
  exit 1
}

config_id=
spec_dir=
board_id=
linkage=()
optim=()
gcc_toolchain_dir=
gcc_toolchain_base_dir=
llvm_toolchain_dir=
llvm_toolchain_base_dir=
benchmark_dir=
benchmark_base_dir=
remote_dir=
remote_base_dir=

while getopts "c:s:i:l:o:t:T:u:U:b:B:r:R:h" opt; do
  case $opt in
    b) benchmark_dir="$OPTARG"
        ;;
    B) benchmark_base_dir="$OPTARG"
        ;;
    c) config_id="$OPTARG"
        ;;
    h) print_help_exit
        ;;
    i) board_id="$OPTARG"
        ;;
    l) linkage+=("$OPTARG")
        ;;
    o) optim+=("$OPTARG")
        ;;
    r) remote_dir="$OPTARG"
        ;;
    R) remote_base_dir="$OPTARG"
        ;;
    s) spec_dir="$OPTARG"
        ;;
    t) gcc_toolchain_dir="$OPTARG"
        ;;
    T) gcc_toolchain_base_dir="$OPTARG"
        ;;
    u) llvm_toolchain_dir="$OPTARG"
        ;;
    U) llvm_toolchain_base_dir="$OPTARG"
        ;;
  esac
done

if [ -z "$llvm_toolchain_dir" ] && [ -z "$llvm_toolchain_base_dir" ]; then
  llvm_toolchain_base_dir=$gcc_toolchain_base_dir
fi

. $(cd `dirname $0` && pwd)/configuration.sh

BENCH_ARCHIVES=()
BENCH_GCC_TOOLCHAINS=()
BENCH_LLVM_TOOLCHAINS=()

function add_benchmark {
  archive=$1
  toolchain=$2

  BENCH_ARCHIVES+=("$1")
  BENCH_GCC_TOOLCHAINS+=("$2")
  BENCH_LLVM_TOOLCHAINS+=("$3")
}

# start counting from 1 to match the help documentation
add_benchmark dummy                   dummy                     dummy

add_benchmark linux/arm/gcc-4.6.4     linux/gcc/arm/gcc-4.6.4   ""
add_benchmark linux/arm/gcc-4.8.1     linux/gcc/arm/gcc-4.8.1   ""
add_benchmark linux/arm/llvm-3.2      linux/gcc/arm/gcc-4.8.1   linux/llvm/llvm-3.2
add_benchmark linux/arm/llvm-3.3      linux/gcc/arm/gcc-4.8.1   linux/llvm/llvm-3.3
add_benchmark linux/arm/llvm-3.4      linux/gcc/arm/gcc-4.8.1   linux/llvm/llvm-3.4
add_benchmark linux/arm/llvm-3.5      linux/gcc/arm/gcc-4.8.1   linux/llvm/llvm-3.5
add_benchmark linux/arm/llvm-3.6      linux/gcc/arm/gcc-4.8.1   linux/llvm/llvm-3.6

add_benchmark linux/thumb/gcc-4.6.4   linux/gcc/thumb/gcc-4.6.4 ""
add_benchmark linux/thumb/gcc-4.8.1   linux/gcc/thumb/gcc-4.8.1 ""
add_benchmark linux/thumb/llvm-3.2    linux/gcc/thumb/gcc-4.8.1 linux/llvm/llvm-3.2
add_benchmark linux/thumb/llvm-3.3    linux/gcc/thumb/gcc-4.8.1 linux/llvm/llvm-3.3
add_benchmark linux/thumb/llvm-3.4    linux/gcc/thumb/gcc-4.8.1 linux/llvm/llvm-3.4
add_benchmark linux/thumb/llvm-3.5    linux/gcc/thumb/gcc-4.8.1 linux/llvm/llvm-3.5
add_benchmark linux/thumb/llvm-3.6    linux/gcc/thumb/gcc-4.8.1 linux/llvm/llvm-3.6

add_benchmark linux/i486/gcc-4.6.4    linux/gcc/i486/gcc-4.6.4  ""
add_benchmark linux/i486/gcc-4.8.1    linux/gcc/i486/gcc-4.8.1  ""
add_benchmark linux/i486/llvm-3.2     linux/gcc/i486/gcc-4.8.1  linux/llvm/llvm-3.2
add_benchmark linux/i486/llvm-3.3     linux/gcc/i486/gcc-4.8.1  linux/llvm/llvm-3.3
add_benchmark linux/i486/llvm-3.4     linux/gcc/i486/gcc-4.8.1  linux/llvm/llvm-3.4
add_benchmark linux/i486/llvm-3.5     linux/gcc/i486/gcc-4.8.1  linux/llvm/llvm-3.5
add_benchmark linux/i486/llvm-3.6     linux/gcc/i486/gcc-4.8.1  linux/llvm/llvm-3.6

add_benchmark android/arm/gcc-4.6     android/gcc/thumb/gcc-4.6 ""
add_benchmark android/arm/gcc-4.8     android/gcc/thumb/gcc-4.8 ""
add_benchmark android/arm/llvm-3.3    android/gcc/thumb/gcc-4.8 android/llvm/llvm-3.3
add_benchmark android/arm/llvm-3.4    android/gcc/thumb/gcc-4.8 android/llvm/llvm-3.4

add_benchmark android/thumb/gcc-4.6   android/gcc/thumb/gcc-4.6 ""
add_benchmark android/thumb/gcc-4.8   android/gcc/thumb/gcc-4.8 ""
add_benchmark android/thumb/llvm-3.3  android/gcc/thumb/gcc-4.8 android/llvm/llvm-3.3
add_benchmark android/thumb/llvm-3.4  android/gcc/thumb/gcc-4.8 android/llvm/llvm-3.4

add_benchmark linux/aarch64/gcc-4.8.1 linux/gcc/aarch64/gcc-4.8.1 ""

# parameters:
#  1: path to archive file
#  2: destination directory
#  3: path to required SPEC tools
#  4: path to desired local GCC toolchain
#  5: path to desired local LLVM toolchain
#  6: board identification
#  7: remote directory (should at least be '.')
function setup_benchmarks {
  old_pwd=`pwd`
  archive_file=$(cd `dirname $1` && pwd)/`basename $1`
  absolute_spec_path=`cd $3 && pwd`
  absolute_gcc_toolchain_path=`cd $4 && pwd`
  absolute_llvm_toolchain_path=`cd $5 && pwd`
  board_id=$6
  if [ -z "$7" ]; then
    remote_directory="."
  else
    remote_directory=$7
  fi

  create_dir "$2"
  destination_directory=`cd $2 && pwd`
  cd $destination_directory

  echo "extracting benchmarks to $destination_directory"
  tar xf $archive_file

  # look up board-specific variables
  remote_host=`get_variable ${board_id}_HOST`
  remote_port=`get_variable ${board_id}_PORT`
  remote_user=`get_variable ${board_id}_USER`
  remote_key=`get_variable ${board_id}_KEY`
  remote_timeout=`get_variable ${board_id}_TIMEOUT`

  echo "patching files"
  for i in `ls -d */`; do
    cd $i

    # look up the map file
    mapfile=`find . -iname "*.map"`

    # adapt toolchain path
    for f in make.out ${mapfile}
    do
      if [ -f $f ]; then
        sed -i "s:DIABLO_TOOLCHAIN_PATH:${absolute_gcc_toolchain_path}:g" $f
        sed -i "s:DIABLO_SPEC_TOOLS:${absolute_spec_path}:g" $f
        sed -i "s:DIABLO_LLVM_TOOLCHAIN_PATH:${absolute_llvm_toolchain_path}:g" $f
      fi
    done

    for f in `find . -iname "*.sh"`
    do
      sed -i "s:DIABLO_BENCHMARK_REMOTE_PORT:${remote_port}:g" $f
      sed -i "s:DIABLO_BENCHMARK_REMOTE_USER:${remote_user}:g" $f
      sed -i "s:DIABLO_BENCHMARK_REMOTE_HOST:${remote_host}:g" $f
      sed -i "s:DIABLO_BENCHMARK_REMOTE_KEY:${remote_key}:g" $f

      sed -i "s:DIABLO_BENCHMARK_REMOTE_DIRECTORY:${remote_directory}:g" $f
      sed -i "s:DIABLO_BENCHMARK_REMOTE_TIMEOUT:${remote_timeout}:g" $f

      sed -i "s:DIABLO_SPEC_TOOLS:${absolute_spec_path}:g" $f
    done

    if [ -f make.out ]; then
      sed -i "1i cd ${absolute_spec_path} && . shrc && cd - > /dev/null" make.out
    fi

    ln -s ${absolute_spec_path}/inputs/$i/input input
    ln -s ${absolute_spec_path}/inputs/$i/reference reference

    cd - > /dev/null
  done

  for f in `find . -iname "*.conf"`; do
    sed -i "s:TEMPLATE_BASEDIR:${destination_directory}:g" $f
  done

  cd $old_pwd
}

function get_remote_directory {
  if [ -z "$remote_base_dir" ]; then
    echo "$remote_dir"
  elif [ ! -z "$remote_base_dir" ]; then
    echo "./$remote_base_dir/$1"
  else
    echo ""
  fi
}

function get_gcc_toolchain_path {
  if [ -z "$gcc_toolchain_base_dir" ] && [ ! -z "$gcc_toolchain_dir" ]; then
    # base directory not defined
    echo "$gcc_toolchain_dir"
  elif [ ! -z "$gcc_toolchain_base_dir" ]; then
    # base directory defined as non-empty
    echo "$gcc_toolchain_base_dir/$1"
  else
    echo "please define either a GCC toolchain base directory or a specific GCC toolchain path"
    return 1
  fi
}

function get_llvm_toolchain_path {
  if [ -z "$llvm_toolchain_base_dir" ] && [ ! -z "$llvm_toolchain_dir" ]; then
    # base directory not defined
    echo "$llvm_toolchain_dir"
  elif [ ! -z "$llvm_toolchain_base_dir" ]; then
    # base directory defined as non-empty
    echo "$llvm_toolchain_base_dir/$1"
  else
    echo "please define either a toolchain base directory or a specific LLVM toolchain path"
    return 1
  fi
}

function get_benchmark_path {
  if [ -z "$benchmark_base_dir" ]; then
    # base directory not defined
    # this is only valid if one and only one benchmark series needs to be installed
    if [ ${#linkage[@]} -gt 1 ] || [ ${#optim[@]} -gt 1 ]; then
      echo "can't use a single directory to store different benchmark sets in,"
      echo "please provide a benchmark base directory instead or install one benchmark set at a time."
      echo "   benchmark sets to be installed: linkage (${linkage[*]})  optimisations (${optim[*]})"
      return 1
    fi

    echo "$benchmark_dir"
  elif [ ! -z "$benchmark_base_dir" ]; then
    # base directory defined as non-empty
    echo "$benchmark_base_dir/$1"
  else
    echo "please provide either a benchmark base directory or a specific destination path"
    return 1
  fi
}

# parameter checking
check_empty "$config_id" "please provide a configuration id"
if [ $config_id -lt 1 ]; then
  echo "error: configuration id should be positive (got $config_id)"
  exit
fi

check_empty "$spec_dir" "please provide the SPEC2006 installation directory"

# auto-fill arrays if necessary
if [ ${#linkage[@]} -eq 0 ]; then
  linkage+=("static")
  linkage+=("dynamic")
  linkage+=("dynamic-pie")
fi

if [ ${#optim[@]} -eq 0 ]; then
  optim+=("0")
  optim+=("1")
  optim+=("2")
  optim+=("3")
  optim+=("s")
fi

check_empty "$board_id" "please provide a board identification string"

if [ -z "$benchmark_dir" ] && [ -z "$benchmark_base_dir" ]; then
  echo "please provide either a (base) directory to store the benchmarks in"
  exit
fi

for linkage_level in "${linkage[@]}"; do
  if [ "$linkage_level" != "static" ] &&
     [ "$linkage_level" != "dynamic" ] &&
     [ "$linkage_level" != "dynamic-pie" ]; then
    echo "Link method \"$linkage_level\" not supported."
    echo "  Only methods \"static\", \"dynamic\" and \"dynamic-pie\" are supported."
    exit 1
  fi
done

for opt_level in "${optim[@]}"; do
  if [ "$opt_level" != "0" ] &&
     [ "$opt_level" != "1" ] &&
     [ "$opt_level" != "2" ] &&
     [ "$opt_level" != "3" ] &&
     [ "$opt_level" != "s" ]; then
    echo "Optimisation level \"$opt_level\" not supported."
    echo "  Only levels \"0\", \"1\", \"2\", \"3\" and \"s\" are supported."
    exit 1
  fi
done

# iterate over linkage and optimisation levels
for linkage_level in "${linkage[@]}"; do
  for opt_level in "${optim[@]}"; do
    bench_path=`get_benchmark_path ${BENCH_ARCHIVES["$config_id"]}/$linkage_level/O$opt_level`
    if [ $? -ne 0 ]; then
      echo $bench_path
      exit
    fi

    gcc_toolchain_path=`get_gcc_toolchain_path ${BENCH_GCC_TOOLCHAINS["$config_id"]}`
    if [ $? -ne 0 ]; then
      echo $gcc_toolchain_path
      exit
    fi
    if [ ! -d $gcc_toolchain_path ]; then
      echo "the toolchain at $gcc_toolchain_path is not installed yet, please install it first and then re-execute this script"
      exit
    fi

    llvm_toolchain_path=""

    # is an LLVM toolchain needed?
    if [ ! -z "${BENCH_LLVM_TOOLCHAINS["$config_id"]}" ]; then
      llvm_toolchain_path=`get_llvm_toolchain_path ${BENCH_LLVM_TOOLCHAINS["$config_id"]}`

      if [ $? -ne 0 ]; then
        echo $llvm_toolchain_path
        exit
      fi
      if [ ! -d $llvm_toolchain_path ]; then
        echo "the toolchain at $llvm_toolchain_path is not installed yet, please install it first and then re-execute this script"
        exit
      fi
    fi

    remote=`get_remote_directory $bench_path`

    tmp_file=`make_temp_suffix .tar.bz2`
    file_name=/mnt/data/benchmarks/spec2006/${BENCH_ARCHIVES["$config_id"]}/$linkage_level/O$opt_level.tar.bz2
    download $file_name  $tmp_file
    setup_benchmarks $tmp_file $bench_path $spec_dir $gcc_toolchain_path "$llvm_toolchain_path" $board_id $remote

    rm $tmp_file
  done
done
