Introduction
============

This directory contains the files necessary to install MiBench and to set it
up for regression testing using the ../common/regression-main/regression.py
script.

Installing and building
=======================

Executing the ./install.sh script without parameters shows a help screen. An
example usage is shown below:

  ./install.sh -j 8 -d /home/jmaebe/private/mibenchinst/mibench-arm-O1 \
  -O "-O1" \
  -t /home/jmaebe/toolchains/diablo-gcc-4.3.6-binutils-2.18-eglibc-2.11-arm \
  -p arm-unknown-linux-gnueabi \
  -e little

If you want to build with clang, add e.g.
  -C /home/jmaebe/diablo/toolchains/diablo-clang34

Setup
=====

Once the MiBench benchmarks have been compiled, they can be set up for testing
via the ../common/regression-main/regression.py script by using the
./mibench2regression.sh script. Again, executing this script without parameters
will show a help screen. An example usage is shown below:

  ./mibench2regression.sh -s "-c blowfish -p 914 jmaebe@drone" \
  -r mibench -p /home/jmaebe/private/setupspec2006/mibench \
  -d ~/diablo/regression/arm/mibench \
  -a arm-softfp-gcc436-eglibc211 \
  -e little

Tips:
* you can use the -w parameter to specify a wrapper that will be used for 
remote executions (e.g. -w qemu-arm)

Look at ../common/regression-main/README.txt for information on how to use the
regression.py script. The configuration file for this set of benchmars is
called mibench.conf and is installed in the directory specified by -d

