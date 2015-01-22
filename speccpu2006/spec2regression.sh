#!/bin/bash

set -eu

source `dirname "$0"`/../common/scripthelpers/benchinstall.rc


# save starting dir
STARTUP_DIR=`pwd`

# check if we can find our bench helper data
HELPER_DATA_DIR="$STARTUP_DIR"/helperdata
if [ ! -f "$HELPER_DATA_DIR"/401.bzip2/runme_test.sh.org ]; then
  HELPER_DATA_DIR="`dirname \"$0\"`"/helperdata
  if [ ! -f "$HELPER_DATA_DIR"/401.bzip2/runme_test.sh.org ]; then
    echo Cannot find \"helperdata\" directory in the current directory nor in the directory containing this script
    exit 1
  fi
fi

print_help_exit() {
cat <<HELP
This script sets up SPEC benchmarks for remote execution and checking 

Usage: $0 [-n] [-s <SSH_PARAS>] [-r <SSH_REMOTE_DIR] -p <SPEC_INSTALLED_DIR> -b <SPEC_BUILD_DIR> -d <TARGET_DIR> -e <ARCH_ENDIANESS>
  -n                     (opt) Skip copying the benchmarks to TARGET_DIR (assumes they already exist)
  -s SSH_PARAS           (opt) ssh parameters for logging in to remote system for executing benchmarks (e.g. "-p 914 -c blowfish jmaebe@drone")
  -r SSH_REMOTE_DIR      (opt) directory used on remote system for testing (default: home directory; must already exist)
  -p SPEC_INSTALLED_DIR  (req) Top level directory where SPEC_CPU2006 was installed
  -b SPEC_BUILD_DIR      (req unless -n) Specify the name of the SPEC_CPU2006 build directory (found in SPEC_INSTALLED_DIR/benchspec/CPU2006/*/build, e.g. build_base_CONFIG-nn.0000)
  -d TARGET_DIR          (req) Directory in which to copy the benchmarks, input/output files and run scripts (e.g. \$HOME/regression/arm/spec2006; will be created if necessary)
  -e ARCH_ENDIANESS      (opt) Endianness of the target platform ("little" or "big", default: little)
  -R                     (opt) also install "reference" spec input/output/config files
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
ARCH_ENDIANESS=le
WRAPPER=
WORDSIZE=32
BENCH_TIMEOUT=
SIZES="test train"

while getopts ns:r:p:b:d:a:e:Rt:W:w:h\? opt; do
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
    e) case "$OPTARG" in
         little) ARCH_ENDIANESS=le
           ;;
         big) ARCH_ENDIANESS=be
           ;;
         *) echo "Invalid -e value, must be little or big"
           ;;
       esac
      ;;
    R) SIZES="test train ref"
      ;;
    t) BENCH_TIMEOUT="ulimit -t $OPTARG \&\&"
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
checkempty "$ARCH_ENDIANESS" -e

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
  if [ -d "$dir"/build/"$SPEC_BUILD_DIR" ] && ! grep -q "^specmake: .*Error" "$dir"/build/"$SPEC_BUILD_DIR"/make.err; then
    if [ "x${SPEC_COPY_BENCHMARKS}" = xy ]; then
      if [ -d "$TARGET_DIR"/"$benchdir" ] ; then
        rm -rf "$TARGET_DIR"/"$benchdir"
      fi
      cp -R "$dir"/build/"$SPEC_BUILD_DIR" "$TARGET_DIR"/"$benchdir"
    fi
  else
    MISSING_BENCHMARKS="$MISSING_BENCHMARKS $benchdir"
  fi
done

if [ "x${SPEC_COPY_BENCHMARKS}" = xy ]; then
# copy input files into benchmark directories
  for dir in "$SPEC_INSTALLED_DIR"/benchspec/CPU2006/*/; do
    benchdir=`basename "$dir"`
    destdir="$TARGET_DIR"/"$benchdir"
    if [ ! -f "$destdir"/input.copied ] ; then
      mkdir -p "$destdir"/input
      if [ -d "$dir"/data/all/input ] ; then
        mkdir -p "$destdir"/input/all
        cp -R "$dir"/data/all/input/* "$destdir"/input/all
      fi
      for size in $SIZES; do
        if [ -d "$dir"/data/$size/input ] ; then
          mkdir -p "$destdir/input/$size"
          cp -R "$dir"/data/$size/input/* "$destdir"/input/$size
        fi
      done
    fi
    touch "$destdir"/input.copied
  done

# sphinx needs an extra file and have its input files renamed
  pushd . > /dev/null
  cd "$TARGET_DIR"/482.sphinx3/input
  rm -f ctlfile
  for file in */*."$ARCH_ENDIANESS".raw
  do
    DIR=`dirname $file`
    base=`basename $file ."$ARCH_ENDIANESS".raw`
    mv $file $DIR/$base.raw
    echo $base `stat -c %s $DIR/$base.raw` >> $DIR/ctlfile
  done
  popd > /dev/null

# wrf needs extra input files
  pushd . > /dev/null
  cd "$TARGET_DIR"/481.wrf/input
  for file in "all/$ARCH_ENDIANESS/$WORDSIZE/*"
  do
    cp $file all
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
    for size in $SIZES; do
      mkdir -p "$destdir"/reference/$size
      cp -R "$dir"/data/"$size"/output/* "$destdir"/reference/"$size"

      if [ -d "$dir"/data/all/output ]; then
        cp -R "$dir"/data/all/output/* "$destdir"/reference/"$size"
      fi
    done
  fi
done

# libquantum output file contains crlf, convert
for size in $SIZES; do
  mv "$TARGET_DIR"/462.libquantum/reference/$size/$size.out "$TARGET_DIR"/462.libquantum/reference/$size/$size.out.org
  tr -d '\r' < "$TARGET_DIR"/462.libquantum/reference/$size/$size.out.org > "$TARGET_DIR"/462.libquantum/reference/$size/$size.out
done

# copy all runscripts and config files
cd "$HELPER_DATA_DIR"
for dir in */ ; do
  cp "$dir"/* "$TARGET_DIR"/"$dir"
done

for conffile in *.conf; do
  sed -e "s!TEMPLATE_BASEDIR!$TARGET_DIR!" < "$conffile" > "$TARGET_DIR"/"$conffile"
  # filter out benchmarks that weren't compiled from main configfile
  for bench in $MISSING_BENCHMARKS; do
    benchlinestart=`grep -n $bench "$TARGET_DIR"/$conffile 2>/dev/null | head -n 1 | sed -e 's/:.*//'`
    if [ ! -z "$benchlinestart" ]; then
      echo "Removing $bench from "$TARGET_DIR"/$conffile because it was not (correctly) compiled"
      (
        head -n $(($benchlinestart-2)) < "$TARGET_DIR"/$conffile
        tail -n +$(($benchlinestart+4)) < "$TARGET_DIR"/$conffile
      ) > "$TARGET_DIR"/$conffile.new
      mv "$TARGET_DIR"/$conffile.new "$TARGET_DIR"/$conffile
    fi
  done
done
cd "$STARTUP_DIR"

# modify runmescripts for remote execution if necessary
for file in "$TARGET_DIR"/*/runme_*.sh.org
do
  size=`basename $file .sh.org | sed -e 's/^runme_//' -e "s/_.*//"`
# skip reference scripts if not installed
  if [ ! -d `dirname "$file"`/reference/$size ]; then
    continue
  fi
  dir=`dirname "$file"`
  dir=`basename "$dir"`
  destfile=`dirname "$file"`/`basename "$file" .org`
  helperfile=`dirname "$file"`/do_`basename "$file" .org`
# extract actual testing commands and put them in a separate script for timing
  echo '#!/bin/bash' > "$helperfile"
  tail -n +2 "$file" | sed -e "s!.*! $BENCH_TIMEOUT $WRAPPER &!" >> "$helperfile"
  chmod +x "$helperfile"
  (
   echo '#!/bin/bash'
   if [ x"${SSH_PARAS}" != x ]; then
# all files to copy (input files have been copied into the main directory by regression.py already)
     echo 'files=`ls -1 -d *|egrep -v "b\.out|diablo_log|^runme.*\.sh"`'
# delete possible leftovers from a previous test
     echo ssh "$SSH_PARAS" "'mkdir -p \"$SSH_REMOTE_DIR\"/$dir && cd \"$SSH_REMOTE_DIR\"/$dir && rm -rf *'"
# copy all new files over
     echo 'tar cf - $files | ssh' "$SSH_PARAS" "'cd \"$SSH_REMOTE_DIR\"/$dir && tar xmpf -'"
# extract actual testing commands and prefix them with the ssh command
     echo 'dotime=$1'
     echo 'collectprofile=$2'
     echo "SAVEPROFILECMD="
     echo "SCPPROFILEFILE="
     echo "rm -f mergedbinprofile"
     echo 'if [ $collectprofile -eq 1 ]; then'
     echo '  SAVEPROFILECMD="&& cat profiling_section.* >> mergedbinprofile"'
     echo '  SCPPROFILEFILE=",mergedbinprofile"'
     echo 'fi'
     echo 'if [ $dotime -eq 1 ]; then'
     echo "   echo Executing remotely: "./`basename $helperfile`"; ssh $SSH_PARAS \"cd '$SSH_REMOTE_DIR'/$dir && /usr/bin/time -o benchtime.out -f '%S\n%U' ./"`basename $helperfile`"\""
     echo "else"
     tail -n +2 "$file" | sed -e "s!.*!  echo Executing remotely: '&'; ssh $SSH_PARAS \"cd '$SSH_REMOTE_DIR'/$dir \&\& $BENCH_TIMEOUT $WRAPPER & \$SAVEPROFILECMD\"!"
     echo "fi"
# get the names of the output files that should be checked
     cd `dirname "$file"`/reference/$size
# grep returns an error if no output
set +e
     reffiles=`ls -1 | egrep -v '\.out$|\.err$'|tr '\n' ','`
set -e
     reffiles=$reffiles"*.out,*.err"
     cd - > /dev/null
# add command to copy the output files back to this machine
     SCP_PARAS=`echo $SSH_PARAS | sed -e 's!-p *\([^ \t][^ \t]*\)!-P \1!'`
# curly brances are only expanded if there's at least one comma :/
     echo "scp $SCP_PARAS:\"${SSH_REMOTE_DIR}/$dir/\"{"${reffiles}\$\{SCPPROFILEFILE\}"}" .
   else
     echo 'dotime=$1'
     echo 'collectprofile=$2'
     echo "SAVEPROFILECMD="
     echo "rm -f mergedbinprofile"
     echo 'if [ $collectprofile -eq 1 ]; then'
     echo '  SAVEPROFILECMD="&& cat profiling_section.* >> mergedbinprofile"'
     echo 'fi'
     echo 'if [ $dotime -eq 1 ]; then'
     echo "  echo Executing: ./"`basename $helperfile`
     echo "  /usr/bin/time -o benchtime.out -f '%S\n%U' ./"`basename $helperfile`
     echo "else"
# the eval to make sure the shell interprets the && from the SAVEPROFILECMD variable
     tail -n +2 "$file" | sed -e "s!.*!  echo Executing: '&' ; eval $BENCH_TIMEOUT $WRAPPER & \$SAVEPROFILECMD!"
     echo "fi"
   fi
  ) > "$destfile"
  chmod +x "$destfile"
done

for file in "$TARGET_DIR"/*/compare_*.sh
do
  benchdir=`dirname $file`
  sed -i -e "s+VAR_SPEC_INSTALL_DIRECTORY+$SPEC_INSTALLED_DIR+" $file
  chmod +x $file
done
echo Done!

