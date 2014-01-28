#!/bin/bash

set -u

print_help_exit() {
cat<<HELP
This script installs MiBench and builds it with a particular toolchain.

Usage: $0 [-n] [-k] [-j <MIBENCH_PAR_BUILD>] [-O <MIBENCH_OPT_FLAGS>] -d <MIBENCH_TARGET_DIR> -t <CT_INSTALLED_DIR> -p <CT_PREFIX>
  -n                     (opt) Do not download the benchmarks (assume the packed version still exists in ./downloads)
  -k                     (opt) Keep downloaded MiBench archive files (default: no)
  -j MIBENCH_PAR_BUILD   (opt) Specify the make -j factor for building the MiBench benchmarks (default: 2)
  -O MIBENCH_OPT_FLAGS   (opt) Specify optimization flags to compile the benchmarks (default: -O2)
  -d MIBENCH_TARGET_DIR  (req) Specify the directory where MiBench should be installed
  -t CT_INSTALLED_DIR    (req) Specify the directory under which the crosstools have been installed (parameter passed to build.sh of Diablo binutils)
  -p CT_PREFIX           (req) Specify the prefix of the used binutils (e.g. arm-unknown-linux-gnueabi)
  -e ARCH_ENDIANESS      (opt) Endianness of the target platform ("little" or "big", default: little)
  -h/-?                  (opt) Print this text and exit
HELP
exit 1
}

# arg1: string to check whether it's not empty
# arg2: name of the parameter that should have been set
checkempty() {
  if [ x"$1" = x ]; then
    echo
    echo Error: Missing required parameter $2
    echo
    print_help_exit
  fi
}

# arg 1: name of the directory to create and whose resolved path (without ".." etc) to output
dir_make_and_resolve()
{
   mkdir -p "$1" 
   cd "$1" 2>/dev/null || return $?  # cd to desired directory; if fail, quell any error messages but return exit status
  echo "`pwd -P`" # output full, link-resolved path
}

# arg 1: url to download; will delete previous version of download if it exists
download()
{
  filename=`echo "$1"|sed -e 's+.*/++g'`
  rm -f "$filename"
# don't quote DOWNLOAD_CMDLINE, contains both program and parameters
  $DOWNLOAD_CMDLINE "$1"
  if [ $? -ne 0 ]; then
    echo Failed to download $1
    echo
    exit 1
  fi
}

MIBENCH_FILES="automotive consumer network office security telecomm"
DOWNLOAD_MIBENCH=y
KEEP_DOWNLOADED_MIBENCH=n
MIBENCH_PARALLEL_BUILD_FACTOR=2
MIBENCH_OPT_FLAGS=-O2
ARCH_ENDIANESS=le

MIBENCH_TARGET_DIR=
CROSSTOOLS_INSTALLED_DIR=
CROSSTOOLS_PREFIX=

while getopts nkj:O:d:t:p:e:h\? opt; do
  case $opt in
    n) DOWNLOAD_MIBENCH=n
      ;;
    k) KEEP_DOWNLOADED_MIBENCH=y
      ;;
    j) MIBENCH_PARALLEL_BUILD_FACTOR="$OPTARG"
      ;;
    O) MIBENCH_OPT_FLAGS="$OPTARG"
      ;;
    d) MIBENCH_TARGET_DIR="$OPTARG"
      ;;
    t) CROSSTOOLS_INSTALLED_DIR="$OPTARG" 
      ;;
    p) CROSSTOOLS_PREFIX="$OPTARG"
      ;;
    e) case "$OPTARG" in
         little) ARCH_ENDIANESS=le
           ;;
         big) ARCH_ENDIANESS=be
           ;;
         *) echo "Invalid -e value, must be little or big"
           ;;
       esac
      ;;
    h | \?) print_help_exit
      ;;
  esac
done
shift `expr $OPTIND - 1`

# save starting dir
STARTUP_DIR=`pwd`

# check arguments
case x"$DOWNLOAD_MIBENCH" in
  xn) for file in $MIBENCH_FILES; do
        if [ ! -f "downloads/$file.tar.gz" ]; then
          echo "Error: cannot find downloads/$file.tar.gz, MiBench does not seem to be downloaded yet"
          echo
          exit 1
        fi
      done
    ;;
  *) DOWNLOAD_CMDLINE=
     wget --version >/dev/null 2>&1
     if [ $? -eq 0 ]; then
       DOWNLOAD_CMDLINE=wget
     else
# curl exits with exit code 2 when printing the version number
# 127 comes from the shell and means "command not found"
       curl --version >/dev/null 2>&1
       if [ $? -ne 127 ]; then
         DOWNLOAD_CMDLINE="curl -O"
       else
         echo "This script requires either wget or curl to be installed and in the path. Cannot execute either."
         echo
         exit 1
       fi
     fi
    ;;
esac

checkempty "$MIBENCH_TARGET_DIR" -d
checkempty "$CROSSTOOLS_INSTALLED_DIR" -t
checkempty "$CROSSTOOLS_PREFIX" -p
checkempty "$ARCH_ENDIANESS" -e

# check if we can find the patches we need
PATCHES_DIR="$STARTUP_DIR"/patches
if [ ! -f "$PATCHES_DIR"/mibench-makefiles.patch ]; then
  PATCHES_DIR="`dirname \"$0\"`"/patches
  if [ ! -f "$PATCHES_DIR"/mibench-makefiles.patch ]; then
    echo Cannot find patches directory in the current directory nor in the directory containing this script
    exit 1
  fi
fi

# check if we can find our bench helper data
HELPER_DATA_DIR="$STARTUP_DIR"/helperdata
if [ ! -f "$HELPER_DATA_DIR"/conffiles/automotive/basicmath/regression_small.conf ]; then
  HELPER_DATA_DIR="`dirname \"$0\"`"/helperdata
  if [ ! -f "$HELPER_DATA_DIR"/conffiles/automotive/basicmath/regression_small.conf ]; then
    echo Cannot find \"helperdata\" directory in the current directory nor in the directory containing this script
    exit 1
  fi
fi

# get absolute path
PATCHES_DIR="`dir_make_and_resolve \"${PATCHES_DIR}\"`"

# sanity check for crosstools install dir
if [ ! -x "$CROSSTOOLS_INSTALLED_DIR"/"$CROSSTOOLS_PREFIX"/bin/"$CROSSTOOLS_PREFIX"-gcc ]; then
  echo "$CROSSTOOLS_INSTALLED_DIR"/"$CROSSTOOLS_PREFIX"/bin/"$CROSSTOOLS_PREFIX"-gcc does not exist or is not executable, check "<CT_INSTALLED_DIR> and <CT_PREFIX> parameters to this script"
  echo
  exit 1
fi

# create the destination directory and resolve it to an absolute path
MIBENCH_TARGET_DIR="`dir_make_and_resolve \"${MIBENCH_TARGET_DIR}/mibench\"`"
if [ $? -ne 0 ]; then
  echo "Unable to create destination directory $MIBENCH_TARGET_DIR..."
  exit 1
fi

# download mibench
DOWNLOAD_DIR="`dir_make_and_resolve \"${STARTUP_DIR}/downloads\"`"
if [ $? -ne 0 ]; then
  echo "Unable to create downloads directory ${STARTUP_DIR}/downloads"
  echo
  exit 1
fi
if [ x"$DOWNLOAD_MIBENCH" = xy ]; then
  echo Downloading MiBench...
  cd "$DOWNLOAD_DIR"
  for file in $MIBENCH_FILES; do
    download "http://www.eecs.umich.edu/mibench/${file}.tar.gz"
  done
  cd "$STARTUP_DIR"
fi

# unpack MiBench in target directory
echo "Unpacking MiBench"...
cd "$MIBENCH_TARGET_DIR"
for file in $MIBENCH_FILES; do
  rm -rf "$file"
  tar xzf "$DOWNLOAD_DIR/$file.tar.gz"
done
cd "$STARTUP_DIR"

if [ x"$KEEP_DOWNLOADED_MIBENCH" != xy ]; then
  rm -rf "$DOWNLOAD_DIR"
fi

# patch makefiles
echo "Building MiBench... ($MIBENCH_TARGET_DIR/build.log)"
cd "$MIBENCH_TARGET_DIR"
SHA_LITTLE_ENDIAN_DEFINE=`echo $ARCH_ENDIANESS | sed -e "s/le/-DLITTLE_ENDIAN/g" -e "s/be/-DBIG_ENDIAN/g"`
sed -e "s?CT_INSTALLED_DIR?$CROSSTOOLS_INSTALLED_DIR?g" -e "s?CT_PREFIX?${CROSSTOOLS_PREFIX}?g" -e "s?MIBENCH_OPT_FLAGS?$MIBENCH_OPT_FLAGS?g" -e "s?SHA_LITTLE_ENDIAN_DEFINE?${SHA_LITTLE_ENDIAN_DEFINE}?g" < "$PATCHES_DIR"/mibench-makefiles.patch | patch -p1 > /dev/null 2>&1
# patch aes
patch -p1 < "$PATCHES_DIR"/mibench-aes.patch > /dev/null
# patch bitcnts (remove execution output variation)
patch -p1 < "$PATCHES_DIR"/mibench-bitcnts.patch > /dev/null

# compile supported benchmarks (partly in parallel, see http://www.andrewzammit.com/blog/scripting-parallel-bash-commands-jobs/ )
proccount=0
pidlist=''
for dir in automotive/* consumer/jpeg/jpeg-6a consumer/lame/lame3.70 network/dijkstra network/patricia security/rijndael security/sha telecomm/adpcm/src telecomm/CRC32 telecomm/FFT telecomm/gsm office/stringsearch; do
  proccount=$(($proccount + 1))
  cd "$dir"
  make > "$MIBENCH_TARGET_DIR"/build.`basename $dir`.log 2>&1 &
  if [ $? -ne 0 ]; then
    echo Failure building "$dir", see "$MIBENCH_TARGET_DIR"/build.`basename $dir`.log for more info
    echo
    exit 1
  fi
  cd "$MIBENCH_TARGET_DIR"
  lastpid=${!}
  pidlist=`echo "$pidlist $lastpid" | sed 's/^ *//g'`
  if [ $proccount -ge $MIBENCH_PARALLEL_BUILD_FACTOR ]; then
    wait $pidlist; # wait for all PIDs in pidList to finish (don't quote)
    proccount=0; # then reset counter
    pidlist=''; # and reset the list of PIDs
  fi
done
# wait for the final ones
if [ ! -z "$pidlist" ]; then
  wait $pidlist
fi

cd "$MIBENCH_TARGET_DIR"
logfiles=`echo *.log`
head -n 999999 $logfiles > "$MIBENCH_TARGET_DIR"/build.log
rm $logfiles



echo Done, now run mibench2regression.sh to set up the benchmarks for regression testing
