#!/bin/bash

set -eu

source `dirname "$0"`/../common/scripthelpers/benchinstall.rc


# save starting dir
STARTUP_DIR=`pwd`

# check if we can find our bench helper data
HELPER_DATA_DIR="$STARTUP_DIR"/helperdata
if [ ! -f "$HELPER_DATA_DIR"/401.bzip2/runme.sh.org ]; then
  HELPER_DATA_DIR="`dirname \"$0\"`"/helperdata
  if [ ! -f "$HELPER_DATA_DIR"/401.bzip2/runme.sh.org ]; then
    echo Cannot find \"helperdata\" directory in the current directory nor in the directory containing this script
    exit 1
  fi
fi

# check if the specified fp architecture is supported
OVERRIDESDIR="$STARTUP_DIR"/outputoverrides
if [ ! -d "$OVERRIDESDIR" ]; then
  OVERRIDESDIR="`dirname \"$0\"`"/outputoverrides
  if [ ! -d "$OVERRIDESDIR" ]; then
    echo Cannot fined \"outputoverrides\" in the current directory not in the directory containing this script
    echo
    exit 1
  fi
fi

print_help_exit() {
cd "$OVERRIDESDIR"
OVERRIDES=`echo * | sed -e 's/ /, /g'`
cat <<HELP
This script sets up SPEC benchmarks for remote execution and checking 

Usage: $0 [-n] [-s <SSH_PARAS>] [-r <SSH_REMOTE_DIR] -p <SPEC_INSTALLED_DIR> -b <SPEC_BUILD_DIR> -d <TARGET_DIR> -a <FP_ARCH> -e <ARCH_ENDIANESS>
  -n                     (opt) Skip copying the benchmarks to TARGET_DIR (assumes they already exist)
  -s SSH_PARAS           (opt) ssh parameters for logging in to remote system for executing benchmarks (e.g. "-p 914 -c blowfish jmaebe@drone")
  -r SSH_REMOTE_DIR      (opt) directory used on remote system for testing (default: home directory; must already exist)
  -p SPEC_INSTALLED_DIR  (req) Top level directory where SPEC_CPU2006 was installed
  -b SPEC_BUILD_DIR      (req unless -n) Specify the name of the SPEC_CPU2006 build directory (found in SPEC_INSTALLED_DIR/benchspec/CPU2006/*/build, e.g. build_base_CONFIG-nn.0000)
  -d TARGET_DIR          (req) Directory in which to copy the benchmarks, input/output files and run scripts (e.g. \$HOME/regression/arm/spec2006; will be created if necessary)
  -a FP_ARCH             (req) Floating point arch used, supported options: $OVERRIDES
  -e ARCH_ENDIANESS      (opt) Endianness of the target platform ("little" or "big", default: little)
  -t BENCH_TIMEOUT       (opt) Kill benchmarks after they've used BENCH_TIMEOUT cpu time (default: none, parameter is passed to "ulimit -t")
  -w WRAPPER             (opt) Wrap execution of remote commands with this wrapper program
  -W WORDSIZE            (opt) Word size of the target architecture in bits (default: 32)
HELP
exit 1
}

SPEC_COPY_BENCHMARKS=y
SSH_PARAS=
SSH_REMOTE_DIR=.
SPEC_INSTALLED_DIR=
SPEC_BUILD_DIR=
TARGET_DIR=
FP_ARCH=
ARCH_ENDIANESS=le
WRAPPER=
WORDSIZE=32
BENCH_TIMEOUT=

while getopts ns:r:p:b:d:a:e:t:W:w:h\? opt; do
  case $opt in
    n) SPEC_COPY_BENCHMARKS=n
      ;;
    s) SSH_PARAS="$OPTARG"
      ;;
    r) SSH_REMOTE_DIR="$OPTARG"
      ;;
    p) SPEC_INSTALLED_DIR="$OPTARG"
      ;;
    b) SPEC_BUILD_DIR="$OPTARG"
      ;;
    d) TARGET_DIR="$OPTARG"
      ;;
    a) FP_ARCH="$OPTARG"
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
    t) BENCH_TIMEOUT="ulimit -t $OPTARG &&"
      ;;
    W) case "$OPTARG" in
         32) WORDSIZE=32
           ;;
         64) WORDSIZE=64
           ;;
         *) echo "Invalid -w value, must be 32 or 64"
           ;;
       esac
      ;;
    w) WRAPPER="$OPTARG"
      ;;
    h | \?) print_help_exit
      ;;
  esac
done
shift `expr $OPTIND - 1`

checkempty "$TARGET_DIR" -d
checkempty "$SPEC_INSTALLED_DIR" -p
checkempty "$FP_ARCH" -a
checkempty "$ARCH_ENDIANESS" -e

FP_DATA_DIR="$OVERRIDESDIR"/"$FP_ARCH"
if [ ! -d "$FP_DATA_DIR" ]; then
  echo $FP_ARCH is an unsupported architecture, $FP_DATA_DIR not found
  echo Found architecural overrides:
  cd "$OVERRIDESDIR"
  ls -1 | sed -e 's/^/  /'
  exit 1
fi

# get absolute path
HELPER_DATA_DIR="`dir_make_and_resolve \"${HELPER_DATA_DIR}\"`"

if [ "x${SPEC_COPY_BENCHMARKS}" = xy ]; then

  checkempty "$SPEC_BUILD_DIR" -b

# check if the SPEC_INSTALLED_DIR and SPEC_BUILD_DIR exist
  if [ ! -d "$SPEC_INSTALLED_DIR" ]; then
    echo Cannot find SPEC_INSTALLED_DIR at \"$SPEC_INSTALLED_DIR\"
    exit 1
   fi

  if [ ! -d "${SPEC_INSTALLED_DIR}/benchspec/CPU2006/401.bzip2/build/${SPEC_BUILD_DIR}" ]; then
    echo Cannot find SPEC_BUILD_DIR, e.g. \"${SPEC_INSTALLED_DIR}/benchspec/CPU2006/401.bzip2/build/${SPEC_BUILD_DIR}\" does not exst
    exit 1
  fi
fi

# create destination and get absolute path
TARGET_DIR="`dir_make_and_resolve \"${TARGET_DIR}\"`"
if [ $? != 0 ]; then
  echo Unable to create TARGET_DIR
  exit 1
fi

###########
# copy the benchmarks
MISSING_BENCHMARKS=
for dir in "$SPEC_INSTALLED_DIR"/benchspec/CPU2006/*/; do
  benchdir=`basename "$dir"`
  if [ -d "$dir"/build/"$SPEC_BUILD_DIR" ]; then
    if [ "x${SPEC_COPY_BENCHMARKS}" = xy ]; then
      if [ -d "$TARGET_DIR"/"$benchdir" ] ; then
        rm -rf "$TARGET_DIR"/"$benchdir"
      fi
      cp -R "$dir"/build/"$SPEC_BUILD_DIR" "$TARGET_DIR"/"$benchdir"
    fi
  else
    MISSING_BENCHMARKS="$MISSING_BENCHMARKS `echo $benchdir|sed -e 's/[^.]*\.//'`"
  fi
done

if [ "x${SPEC_COPY_BENCHMARKS}" = xy ]; then
# copy input files into benchmark directories
  for dir in "$SPEC_INSTALLED_DIR"/benchspec/CPU2006/*/; do
    benchdir=`basename "$dir"`
    destdir="$TARGET_DIR"/"$benchdir"
    if [ ! -f "$destdir"/input.copied ] ; then
      mkdir -p "$destdir"/inputs
      if [ -d "$dir"/data/test/input ] ; then
        cp -R "$dir"/data/test/input/* "$destdir"/inputs
      fi
      if [ -d "$dir"/data/all/input ] ; then
        cp -R "$dir"/data/all/input/* "$destdir"/inputs
      fi
    fi
    touch "$destdir"/input.copied
  done

# sphinx needs an extra file and have its input files renamed
  pushd . > /dev/null
  cd "$TARGET_DIR"/482.sphinx3/inputs
  rm -f ctlfile
  for file in *."$ARCH_ENDIANESS".raw
  do
    base=`basename $file ."$ARCH_ENDIANESS".raw`
    mv $file $base.raw
    echo $base `stat -c %s $base.raw` >> ctlfile
  done
  popd > /dev/null

# wrf needs extra input files
  pushd . > /dev/null
  cd "$TARGET_DIR"/481.wrf/inputs
  for file in "$ARCH_ENDIANESS/$WORDSIZE/*"
  do
    cp $file ./
  done
  popd > /dev/null


#####################
fi

# copy output files into benchmark directories
for dir in "$SPEC_INSTALLED_DIR"/benchspec/CPU2006/*/; do
  benchdir=`basename "$dir"`
  destdir="$TARGET_DIR"/"$benchdir"
  if [ ! -f "$destdir"/output.copied ] ; then
    mkdir -p "$destdir"/reference
    cp -R "$dir"/data/test/output/* "$destdir"/reference
# arch-specific overrides
    if [ -d "$FP_DATA_DIR"/"$benchdir" ]; then
      cp -R "$FP_DATA_DIR"/"$benchdir"/* "$destdir"/reference
    fi
  fi
done

# libquantum output file contains crlf, convert
mv "$TARGET_DIR"/462.libquantum/reference/test.out "$TARGET_DIR"/462.libquantum/reference/test.out.org
tr -d '\r' < "$TARGET_DIR"/462.libquantum/reference/test.out.org > "$TARGET_DIR"/462.libquantum/reference/test.out

# copy all runscripts and config files
cd "$HELPER_DATA_DIR"
for dir in */ ; do
  cp "$dir"/* "$TARGET_DIR"/"$dir"
done

sed -e "s!TEMPLATE_BASEDIR!$TARGET_DIR!" < spec2006.conf > "$TARGET_DIR"/spec2006.conf
# filter out benchmarks that weren't compiled from main configfile
for bench in $MISSING_BENCHMARKS; do
  benchlinestart=`grep -n $bench "$TARGET_DIR"/spec2006.conf 2>/dev/null | head -n 1 | sed -e 's/:.*//'`
  if [ ! -z "$benchlinestart" ]; then
    echo "Removing $bench from config file because it was not compiled (note that clang does not support Fortran benchmarks)"
    (
      head -n $(($benchlinestart-1)) < "$TARGET_DIR"/spec2006.conf
      tail -n +$(($benchlinestart+5)) < "$TARGET_DIR"/spec2006.conf
    ) > "$TARGET_DIR"/spec2006.conf.new
    mv "$TARGET_DIR"/spec2006.conf.new "$TARGET_DIR"/spec2006.conf
  fi
done
cd "$STARTUP_DIR"

# modify runmescripts for remote execution if necessary
for file in "$TARGET_DIR"/*/runme.sh.org
do
  dir=`dirname "$file"`
  dir=`basename "$dir"`
  destfile=`dirname "$file"`/`basename "$file" .org`
  (
   echo '#!/bin/bash'
   if [ x"${SSH_PARAS}" != x ]; then
# all files to copy (input files have been copied into the main directory by regression.py already)
     echo 'files=`ls -1 -d *|egrep -v "b\.out|diablo_log|runme*.sh"`'
# delete possible leftovers from a previous test
     echo ssh "$SSH_PARAS" "'mkdir -p \"$SSH_REMOTE_DIR\"/$dir && cd \"$SSH_REMOTE_DIR\"/$dir && rm -rf *'"
# copy all new files over
     echo 'tar cf - $files | ssh' "$SSH_PARAS" "'cd \"$SSH_REMOTE_DIR\"/$dir && tar xmf -'"
# extract actual testing commands and prefix them with the ssh command
     tail -n +2 "$file" | sed -e "s!.*!echo Executing remotely: '&'; ssh $SSH_PARAS \"cd '$SSH_REMOTE_DIR'/$dir \&\& $BENCH_TIMEOUT $WRAPPER &\"!"
# get the names of the output files that should be checked
     cd `dirname "$file"`/reference
# grep returns an error if no output
set +e
     reffiles=`ls -1 | egrep -v '\.out$|\.err$'|tr '\n' ','`
set -e
     reffiles=$reffiles"*.out,*.err"
     cd - > /dev/null
# add command to copy the output files back to this machine
     SCP_PARAS=`echo $SSH_PARAS | sed -e 's!-p *\([^ \t][^ \t]*\)!-P \1!'`
# curly brances are only expanded if there's at least one comma :/
     if [[ "$reffiles" =~ .*,.* ]]; then
       echo "scp $SCP_PARAS:\"${SSH_REMOTE_DIR}\"/$dir/{"$reffiles"}" .
     else
       echo "scp $SCP_PARAS:\"${SSH_REMOTE_DIR}\"/$dir/$reffiles" .
     fi
   else
     tail -n +2 "$file" | sed -e "s!.*!echo Executing: '&' ; $BENCH_TIMEOUT $WRAPPER &!"
   fi
  ) > "$destfile"
  chmod +x "$destfile"
done
echo Done!

