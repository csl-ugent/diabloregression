#!/bin/bash

set -eu
shopt -s extglob

print_help_exit() {
cat <<HELP
This script sets up mibench benchmarks for remote execution and checking 

Usage: $0 [-n] [-s <SSH_PARAS>] [-r <SSH_REMOTE_DIR] -p <MIBENCH_INSTALLED_DIR> -d <TARGET_DIR> -a <FP_ARCH> -e <ARCH_ENDIANESS> -w <WRAPPER>
  -n                     (opt) Skip copying the benchmarks to TARGET_DIR (assumes they already exist)
  -s SSH_PARAS           (opt) ssh parameters for logging in to remote system for executing benchmarks (e.g. "-p 914 -c blowfish jmaebe@drone")
  -r SSH_REMOTE_DIR      (opt) directory used on remote system for testing (default: home directory; must already exist)
  -p MIBENCH_INSTALLED_DIR  (req) Top level directory where MIBENCH_CPU2006 was installed
  -d TARGET_DIR          (req) Directory in which to copy the benchmarks, input/output files and run scripts (e.g. \$HOME/regression/arm/mibench; will be created if necessary)
  -a FP_ARCH             (req) Floating point arch used, supported options: arm-softfp-gcc436-eglibc211
  -e ARCH_ENDIANESS      (opt) Endianness of the target platform ("little" or "big", default: little)
  -w WRAPPER             (opt) Wrap execution of remote commands with this wrapper program (only effective if used with -s)
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

MIBENCH_COPY_BENCHMARKS=y
SSH_PARAS=
SSH_REMOTE_DIR=.
MIBENCH_INSTALLED_DIR=
TARGET_DIR=
FP_ARCH=
ARCH_ENDIANESS=le
WRAPPER=

while getopts ns:r:p:d:a:e:w:h\? opt; do
  case $opt in
    n) MIBENCH_COPY_BENCHMARKS=n
      ;;
    s) SSH_PARAS="$OPTARG"
      ;;
    r) SSH_REMOTE_DIR="$OPTARG"
      ;;
    p) MIBENCH_INSTALLED_DIR="$OPTARG"
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
    w) WRAPPER="$OPTARG"
      ;;
    h | \?) print_help_exit
      ;;
  esac
done
shift `expr $OPTIND - 1`

# save starting dir
STARTUP_DIR=`pwd`

checkempty "$TARGET_DIR" -d
checkempty "$MIBENCH_INSTALLED_DIR" -p
checkempty "$FP_ARCH" -a
checkempty "$ARCH_ENDIANESS" -e

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
HELPER_DATA_DIR="`dir_make_and_resolve \"${HELPER_DATA_DIR}\"`"

# check if the specified fp architecture is supported
OVERRIDESDIR="$HELPER_DATA_DIR"/outputoverrides
if [ ! -d "$OVERRIDESDIR" ]; then
  echo Cannot fined \"outputoverrides\" in $HELPER_DATA_DIR
  echo
  exit 1
fi
FP_DATA_DIR="$OVERRIDESDIR"/"$FP_ARCH"
if [ ! -d "$FP_DATA_DIR" ]; then
  echo $FP_ARCH is an unsupported architecture, $FP_DATA_DIR not found
  echo Found architecural overrides:
  cd "$OVERRIDESDIR"
  ls -1 | sed -e 's/^/  /'
  exit 1
fi

if [ "x${MIBENCH_COPY_BENCHMARKS}" = xy ]; then
# check if the MIBENCH_INSTALLED_DIR exists
  if [ ! -d "$MIBENCH_INSTALLED_DIR" ]; then
    echo Cannot find MIBENCH_INSTALLED_DIR at \"$MIBENCH_INSTALLED_DIR\"
    exit 1
  fi 
fi

# create destination and get absolute path
TARGET_DIR="`dir_make_and_resolve \"${TARGET_DIR}\"`"
if [ $? != 0 ]; then
  echo Unable to create $TARGET_DIR
  exit 1
fi

# go to installation dir
cd "$MIBENCH_INSTALLED_DIR"

MIBENCH_DIRS=`echo automotive/* consumer/jpeg/jpeg-6a consumer/lame/lame3.70 network/dijkstra network/patricia security/rijndael security/sha telecomm/adpcm/src telecomm/CRC32 telecomm/FFT telecomm/gsm/src office/stringsearch`
# the runme scripts are always in the top-level benchmark dir
MIBENCH_SCRIPT_DIRS=`echo $MIBENCH_DIRS | sed -e 's!\([^ /]*\)/\([^ /]*\)/\([^ ]*\)!\1/\2!g'`

# copy the benchmarks
if [ "x${MIBENCH_COPY_BENCHMARKS}" = xy ]; then
  echo Copying benchmarks...
  for dir in $MIBENCH_DIRS; do
    benchdir="$dir"
    destdir=`echo $benchdir | sed -e 's!\([^ /]*\)/\([^ /]*\)/\([^ ]*\)!\1/\2!g'`
    if [ -d "$TARGET_DIR"/"$destdir" ] ; then
      rm -rf "$TARGET_DIR"/"$destdir"
    fi
    mkdir -p "$TARGET_DIR"/"$destdir"
# in case of gsm, the binaries/map files are in a separate directory
    mapfiles=`find "$destdir" -name "*.map"`
    binaries=`echo "$mapfiles" |sed -e 's/\.map//g'`
# warning: $mapfiles and $binaries are not safe with spaces in dir names
    cp "$benchdir"/*.o `find "$destdir" -name *.a` $mapfiles $binaries "$TARGET_DIR"/"$destdir"
  done
# gsm has a special directory structure, help diablo
  ln -sf "$TARGET_DIR"/telecomm/gsm "$TARGET_DIR"/telecomm/gsm/src
  ln -sf "$TARGET_DIR"/telecomm/gsm "$TARGET_DIR"/telecomm/gsm/lib
fi

# always re-copy the runme scripts, so they can be modified again for
# different remote execution or so
for dir in $MIBENCH_SCRIPT_DIRS
do
  for file in "$dir"/runme_*.sh
  do
# add "./" to lines executing binaries, and remove subdirectory prefixes (and remove empty lines)
    sed -e 's+^[^#]+./&+' -e 's+^./[^ ]*/+./+' < "$file" | grep -v "^$" > "$TARGET_DIR"/"$file" 
  done
done
# split jpeg into encoding and decoding
grep -v cjpeg < "$TARGET_DIR"/consumer/jpeg/runme_small.sh > "$TARGET_DIR"/consumer/jpeg/runme_djpeg.sh
grep djpeg < "$TARGET_DIR"/consumer/jpeg/runme_large.sh >> "$TARGET_DIR"/consumer/jpeg/runme_djpeg.sh
grep -v djpeg < "$TARGET_DIR"/consumer/jpeg/runme_small.sh > "$TARGET_DIR"/consumer/jpeg/runme_cjpeg.sh
grep cjpeg < "$TARGET_DIR"/consumer/jpeg/runme_large.sh >> "$TARGET_DIR"/consumer/jpeg/runme_cjpeg.sh
chmod +x "$TARGET_DIR"/consumer/jpeg/runme_cjpeg.sh "$TARGET_DIR"/consumer/jpeg/runme_cjpeg.sh
rm "$TARGET_DIR"/consumer/jpeg/runme_{small,large}.sh

# split adpcm into encoding and decoding and capture stderr
grep -v rawdaudio < "$TARGET_DIR"/telecomm/adpcm/runme_small.sh |sed -e 's+data/++' -e 's+pcm$+pcm 2>output_small_c.stderr+' > "$TARGET_DIR"/telecomm/adpcm/runme_rawcaudio.sh
grep -v rawcaudio < "$TARGET_DIR"/telecomm/adpcm/runme_small.sh |sed -e 's+data/++' -e 's+pcm$+pcm 2>output_small_d.stderr+' > "$TARGET_DIR"/telecomm/adpcm/runme_rawdaudio.sh
chmod  +x "$TARGET_DIR"/telecomm/adpcm/runme_raw{c,d}audio.sh
rm "$TARGET_DIR"/telecomm/adpcm/runme_{small,large}.sh

# split gsm into encoding and decoding
grep -vw "untoast" < "$TARGET_DIR"/telecomm/gsm/runme_small.sh |sed -e 's+data/++' > "$TARGET_DIR"/telecomm/gsm/runme_toast.sh
grep -vw "toast" < "$TARGET_DIR"/telecomm/gsm/runme_small.sh |sed -e 's+data/++' > "$TARGET_DIR"/telecomm/gsm/runme_untoast.sh
chmod +x "$TARGET_DIR"/telecomm/gsm/runme_{untoast,toast}.sh
rm "$TARGET_DIR"/telecomm/gsm/runme_{small,large}.sh

# join two lame tests
mv "$TARGET_DIR"/consumer/lame/runme_small.sh "$TARGET_DIR"/consumer/lame/runme.sh
tail -n +1 "$TARGET_DIR"/consumer/lame/runme_large.sh >> "$TARGET_DIR"/consumer/lame/runme.sh
rm "$TARGET_DIR"/consumer/lame/runme_large.sh

# crc runme scripts refer to adpcm input files, always use large.pcm -> fix and make independent
sed -e 's+../adpcm/data/++' -e 's/large/small/' < "$TARGET_DIR"/telecomm/CRC32/runme_small.sh > "$TARGET_DIR"/telecomm/CRC32/runme.sh
chmod +x "$TARGET_DIR"/telecomm/CRC32/runme.sh

if [ "x${MIBENCH_COPY_BENCHMARKS}" = xy ]; then 
  echo Copying inputs and reference outputs...
# copy output files into benchmark directories
  cp -R "$HELPER_DATA_DIR"/reference_output/* "$TARGET_DIR"
# add regression configuration files
  sed -e "s!TEMPLATE_BASEDIR!$TARGET_DIR!" < "$HELPER_DATA_DIR"/conffiles/mibench.conf > "$TARGET_DIR"/mibench.conf
  cd "$HELPER_DATA_DIR/conffiles"
  for dir in */*; do
    cp "$dir"/* "$TARGET_DIR"/$dir
    inputfiles=`cat $dir/*.conf|grep "inputfiles="|sed -e 's/inputfiles=//'`
    for file in $inputfiles; do
# CRC32 input files are those from adpcm
      inputdir=`echo $dir|sed -e "s/CRC32/adpcm/"`
      copyfile="$MIBENCH_INSTALLED_DIR"/"$inputdir"/"$file"
# if not found, look in subdirs
      if [ ! -f "$copyfile" ]; then
        copyfile=`echo "$MIBENCH_INSTALLED_DIR"/"$inputdir"/*/"$file"`
      fi
      cp "$copyfile" "$TARGET_DIR"/"$dir"/"$file"
# arch-specific overrides
      if [ -d "$FP_DATA_DIR"/"$benchdir" ]; then
        cp -R "$FP_DATA_DIR"/"$benchdir"/* "$TARGET_DIR"/"$dir"/"$file"
      fi
    done
  done
fi

# modify runmescripts for remote execution if necessary
echo Patching runscripts...
for file in `find "$TARGET_DIR" -name runme*.sh`
do
  cp "$file" "$file".org
  file=$file.org
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
     tail -n +2 "$file" | sed -e "s!.*!echo Executing remotely: '&'; ssh $SSH_PARAS \"cd '$SSH_REMOTE_DIR'/$dir \&\& $WRAPPER &\"!"
# get the names of the output files that should be checked
     cd `dirname "$file"`/reference
     reffiles=`echo * | sed -e 's/ /,/g'`
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
     tail -n +2 "$file" | sed -e "s!.*!echo Executing: '&' ;$WRAPPER &!"
   fi
  ) > "$destfile"
  chmod +x "$destfile"
done
echo Done!

