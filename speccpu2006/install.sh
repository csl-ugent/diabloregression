#!/bin/bash

source `dirname "$0"`/../common/scripthelpers/benchinstall.rc

set -u

print_help_exit() {
cat<<HELP
This script installs SPEC_CPU2006, configures it for building with a particular toolchain and then builds it

Usage: $0 [-n] [-k] [-f <SPEC_ARCHIVE>] [-j <SPEC_PAR_BUILD>] [-O <SPEC_OPT_FLAGS>] -d <SPEC_TARGET_DIR> -c <SPEC_CONFIG_NAME> -t <CT_INSTALLED_DIR> -p <CT_PREFIX>
  -r                     (opt) Only rebuild installed SPEC with new options, skip installation pass (-n, -k, -f parameters are unnecessary/ignored)
  -n                     (opt) Do not unpack the SPEC_CPU2006 tbz install file (assume the unpacked version still exists in the current dir)
  -k                     (opt) Keep unpacked SPEC_CPU2006 install file
  -f SPEC_ARCHIVE        (opt) Specify the the SPEC_CPU2006 install file (default is CSL one under /afs)
  -j SPEC_PAR_BUILD      (opt) Specify the make -j factor for building the SPEC benchmarks (default: 2)
  -O SPEC_OPT_FLAGS      (opt) Specify optimization flags to compile the benchmarks (default: -O2)
  -D                     (opt) Link benchmarks dynamically instead of statically
  -d SPEC_TARGET_DIR     (req) Specify the directory where SPEC_CPU2006 should be installed
  -c SPEC_CONFIG_NAME    (req) Specify the name of the SPEC_CPU2006 configuration name to generate (freely chooseable)
  -t CT_INSTALLED_DIR    (req) Specify the directory under which the crosstools have been installed (parameter passed to build.sh of Diablo binutils)
  -p CT_PREFIX           (req) Specify the prefix of the used binutils (e.g. arm-unknown-linux-gnueabi)
  -C CLANG_INSTALLED_DIR (opt) Specify the directry in which clang has been installed (will compile benchmarks with clang)
  -h/-?                  (opt) Print this text and exit
HELP
exit 1
}

ONLY_REBUILD=n
UNPACK_SPEC=y
KEEP_UNPACKED_SPEC=n
SPEC_ARCHIVE="/afs/elis/group/csl/perflab/benchmarks/SPEC_CPU2006v1.1.tar.bz2"
SPEC_PARALLEL_BUILD_FACTOR=2
SPEC_OPT_FLAGS=-O2
SPEC_LINK_STRATEGY=-static


SPEC_INSTALLDIR=
SPEC_CONFIG_NAME=
CROSSTOOLS_INSTALLED_DIR=
CROSSTOOLS_PREFIX=
CLANG_INSTALLED_DIR=

while getopts rnkf:j:O:Dd:c:C:t:p:h\? opt; do
  case $opt in
    r) ONLY_REBUILD=y
      ;;
    n) UNPACK_SPEC=n
      ;;
    k) KEEP_UNPACKED_SPEC=y
      ;;
    f) SPEC_ARCHIVE="$OPTARG"
      ;;
    j) SPEC_PARALLEL_BUILD_FACTOR="$OPTARG"
      ;;
    O) SPEC_OPT_FLAGS="$OPTARG"
      ;;
    D) SPEC_LINK_STRATEGY=-Bdynamic
      ;;
    d) SPEC_INSTALLDIR="$OPTARG"
      ;;
    C) CLANG_INSTALLED_DIR="$OPTARG"
      ;;
    c) SPEC_CONFIG_NAME="$OPTARG"
      ;;
    t) CROSSTOOLS_INSTALLED_DIR="$OPTARG" 
      ;;
    p) CROSSTOOLS_PREFIX="$OPTARG"
      ;;
    h | \?) print_help_exit
      ;;
  esac
done
shift `expr $OPTIND - 1`

# save starting dir
STARTUP_DIR=`pwd`

checkempty "$SPEC_INSTALLDIR" -d
checkempty "$SPEC_CONFIG_NAME" -c
checkempty "$CROSSTOOLS_INSTALLED_DIR" -t
checkempty "$CROSSTOOLS_PREFIX" -p

if [ x$ONLY_REBUILD = xn ]; then
# check arguments
  case x"$UNPACK_SPEC" in
    xy) if [ ! -f "$SPEC_ARCHIVE" ]; then
          echo "Error: cannot find SPEC_ARCHIVE $SPEC_ARCHIVE"
          echo
          exit 1
        fi
      ;;
    *) if [ ! -d "SPEC_CPU2006v1.1" ]; then
         echo Error: cannot find unpacked SPEC_CPU2006v1.1 directory
         echo
         exit 1
       fi
      ;;
  esac
fi

# check if we can find the patches we need
PATCHES_DIR="$STARTUP_DIR"/patches
if [ ! -f "$PATCHES_DIR"/spec_config.patch ]; then
  PATCHES_DIR="`dirname \"$0\"`"/patches
  if [ ! -f "$PATCHES_DIR"/spec_config.patch ]; then
    echo Cannot find patches directory in the current directory nor in the directory containing this script
    exit 1
  fi
fi
# get absolute path
PATCHES_DIR="`dir_make_and_resolve \"${PATCHES_DIR}\"`"

# sanity check for crosstools install dir
EXTRA_CROSSTOOLS_PREFIX_DIR=1
if [ ! -x "$CROSSTOOLS_INSTALLED_DIR"/"$CROSSTOOLS_PREFIX"/bin/"$CROSSTOOLS_PREFIX"-gcc ]; then
  EXTRA_CROSSTOOLS_PREFIX_DIR=0
  if [ ! -x "$CROSSTOOLS_INSTALLED_DIR"/bin/"$CROSSTOOLS_PREFIX"-gcc ]; then
    echo Neither "$CROSSTOOLS_INSTALLED_DIR"/bin/"$CROSSTOOLS_PREFIX"-gcc nor "$CROSSTOOLS_INSTALLED_DIR"/"$CROSSTOOLS_PREFIX"/bin/"$CROSSTOOLS_PREFIX"-gcc exists or is not executable, check "<CT_INSTALLED_DIR> and <CT_PREFIX> parameters to this script"
    echo
    exit 1
  fi
fi

# extract architecture from crosstools prefix
SPEC_ARCH=`echo $CROSSTOOLS_PREFIX| cut -d'-' -f 1`

if [ x"$ONLY_REBUILD" = xn ]; then
# create the destination directory and resolve it to an absolute path
  SPEC_INSTALLDIR="`dir_make_and_resolve \"${SPEC_INSTALLDIR}\"`"
  if [ $? -ne 0 ]; then
    echo "Error: Unable to create destination directory $SPEC_INSTALLDIR..."
    echo
    exit 1
  fi

# unpack SPEC2006 in current directory
  if [ x"$UNPACK_SPEC" = xy ]; then
    echo "Unpacking SPEC CPU2006 (will take a while)"...
    tar xjf "$SPEC_ARCHIVE"
# get read of read-only files (comes from a cdrom)
    chmod -R u+w SPEC_CPU2006v1.1
  fi

# install it (may fail while testing the tools)
  echo "Installing SPEC CPU2006 (specinstall.log) ..."
  cd SPEC_CPU2006v1.1
  ./install.sh -f -d "$SPEC_INSTALLDIR" > "$STARTUP_DIR"/specinstall.log 2>&1

  echo "Compiling SPEC CPU2006 tools (spectools.log) ..."
# compile tools
  cd "$SPEC_INSTALLDIR"

  mkdir tools
  cp -R "$STARTUP_DIR"/SPEC_CPU2006v1.1/tools/src tools
  cd tools/src
# some files are read-only, yet have to be overwritten
  chmod -R u+w .
# patch the buildtools script so it doesn't complain if some perl tests fail (it's harmless)
  patch -p1 < "$PATCHES_DIR"/buildtools-ignore-harmless-specperl-error.patch >/dev/null
# patch md5sum so it doesn't redeclare getline/getdelim when unnecessary (causing potential useless conflicts with system headers)
  patch -p1 < "$PATCHES_DIR"/buildtools-md5sum.patch >/dev/null
# patch Perl makefile to link against libm for miniperl
  patch -p1 < "$PATCHES_DIR"/buildtools-perl.patch >/dev/null
# add file to tell perl that it has to link against libm for regular perl
  cat > perl-5.8.8/ext.libs << PERLLIBS
-lm
PERLLIBS
# prevent testing of Zlib
  touch Compress-Zlib-1.34/spec_do_no_tests

# build the SPEC tools
  export BZIP2CFLAGS=-fPIC
  ./buildtools > "$STARTUP_DIR"/spectools.log 2>&1
  if [ $? -ne 0 ]; then
    echo  Building the SPEC CPU2006 tools failed, see spectools.log for details
    exit 1
  fi
  cd ../..
# the SPEC tools are now (hopefully) built
  if [ ! -f tools/output/bin/a2p ]; then
    echo  Building the SPEC CPU2006 tools failed, see spectools.log for details
    exit 1
  fi

# remove the unpacked installer files if not prevented
  if [ x"$KEEP_UNPACKED_SPEC" = xn ]; then
    echo Removing unpacked SPEC_CPU2006 installer dir...
    rm -rf "$STARTUP_DIR"/SPEC_CPU2006v1.1
  fi
else
  # REBUILD_ONLY=y
  if [ ! -f "$SPEC_INSTALLDIR"/tools/output/bin/perl ]; then
    echo "Error: $SPEC_INSTALLDIR does not appear to contain a previously installed SPEC_CPU2006"
    echo
    exit 1
  fi
fi

cd "$SPEC_INSTALLDIR"
# create a config to build the benchmarks with patched toolchain
echo Creating SPEC build configuration...
cp config/Example-linux32-i386-gcc42.cfg config/"$SPEC_CONFIG_NAME".cfg
if [ "$EXTRA_CROSSTOOLS_PREFIX_DIR" -eq 0 ]; then
  CROSSTOOLS_ROOT="$CROSSTOOLS_INSTALLED_DIR/"
  SED_FILTER_EXTRA_CROSSTOOLS_PREFIX_DIR="s+DIABLO_CROSSTOOLS_INSTALLED_DIR/DIABLO_CROSSTOOLS_PREFIX+DIABLO_CROSSTOOLS_INSTALLED_DIR+"
else
  CROSSTOOLS_ROOT="$CROSSTOOLS_INSTALLED_DIR/$CROSSTOOLS_PREFIX"
  SED_FILTER_EXTRA_CROSSTOOLS_PREFIX_DIR="s/willneverexist//"
fi

if [ ! -z "$CLANG_INSTALLED_DIR" ]; then
  SED_FILTER_GCC_TO_CLANG="s!DIABLO_CROSSTOOLS_INSTALLED_DIR/DIABLO_CROSSTOOLS_PREFIX/bin/DIABLO_CROSSTOOLS_PREFIX-gcc!$CLANG_INSTALLED_DIR/bin/clang!g"
  SED_FILTER_GPLUSPLUS_TO_CLANG="s!DIABLO_CROSSTOOLS_INSTALLED_DIR/DIABLO_CROSSTOOLS_PREFIX/bin/DIABLO_CROSSTOOLS_PREFIX-g++!$CLANG_INSTALLED_DIR/bin/clang++!g"
  SPEC_OPT_FLAGS="$SPEC_OPT_FLAGS -isysroot $CROSSTOOLS_ROOT/$CROSSTOOLS_PREFIX/sysroot -no-integrated-as -gcc-toolchain $CROSSTOOLS_ROOT -ccc-gcc-name $CROSSTOOLS_PREFIX -target $CROSSTOOLS_PREFIX"
  SPEC_EXCLUDE_BENCHMARKS="^410.bwaves ^416.gamess ^434.zeusmp ^435.gromacs ^436.cactusADM ^437.leslie3d ^454.calculix ^459.GemsFDTD ^465.tonto ^481.wrf"
else
  GCCVERSION=`"$CROSSTOOLS_ROOT"/bin/"$CROSSTOOLS_PREFIX"-gcc --version|head -1 |sed -e 's/.* //'`
  GCCMAJORVERSION=`echo $GCCVERSION | cut -d '.' -f 1`
  GCCMINORVERSION=`echo $GCCVERSION | cut -d '.' -f 2`
# see http://gcc.gnu.org/gcc-4.8/changes.html
  if test \( $GCCMAJORVERSION -gt 4 \) -o \( $GCCMAJORVERSION -eq 4 -a $GCCMINORVERSION -ge 8 \) ; then
    SPEC_OPT_FLAGS="$SPEC_OPT_FLAGS -fno-aggressive-loop-optimizations"
  fi
  SED_FILTER_GCC_TO_CLANG="s/willneverexist//"
  SED_FILTER_GPLUSPLUS_TO_CLANG="s/willneverexist//"
  SPEC_EXCLUDE_BENCHMARKS=
fi

sed -e "s/SPEC_LINK_STRATEGY/$SPEC_LINK_STRATEGY/g" -e "$SED_FILTER_GCC_TO_CLANG" -e "$SED_FILTER_GPLUSPLUS_TO_CLANG" -e "$SED_FILTER_EXTRA_CROSSTOOLS_PREFIX_DIR" -e "s?DIABLO_SPEC_CONFIG_NAME?$SPEC_CONFIG_NAME?g" -e "s?DIABLO_CROSSTOOLS_INSTALLED_DIR?$CROSSTOOLS_INSTALLED_DIR?g" -e "s?DIABLO_CROSSTOOLS_PREFIX?$CROSSTOOLS_PREFIX?g" -e "s?DIABLO_SPEC_OPTIMIZE_FLAGS?$SPEC_OPT_FLAGS?g" -e "s?SPEC_PARALLEL_BUILD_FACTOR?$SPEC_PARALLEL_BUILD_FACTOR?g"  < "$PATCHES_DIR"/spec_config.patch | patch -p1

echo Building SPEC_CPU2006...
# restore environment to default
set +u
echo "  Executing: cd $SPEC_INSTALLDIR"
cd "$SPEC_INSTALLDIR"
echo "  Executing: source shrc"
source shrc
echo "  Executing: runspec -a build -c $SPEC_CONFIG_NAME --size=test all $SPEC_EXCLUDE_BENCHMARKS >specbuild.log 2>&1"
runspec -a build -c $SPEC_CONFIG_NAME --size=test all $SPEC_EXCLUDE_BENCHMARKS >specbuild.log 2>&1
grep "Error building" specbuild.log
if [ $? -eq 0 ]; then
  echo "   There were errors building some benchmarks, see $SPEC_INSTALLDIR/benchspec/CPU2006/<benchname>/build/build_base_${SPEC_CONFIG_NAME}-nn.0000/make.err for details"
fi
echo Done!
echo
echo "Now execute spec2regression.sh to create a directory layout and configuration scripts that can be used by the regression.py script (see README.txt for an example)"
echo
