Introduction
============

This directory contains the files necessary to install SPEC2006 and to set it
up for regression testing using the ../common/regression-main/regression.py
script.

Installing
==========

Executing the ./install.sh script without parameters shows a help screen. An
example usage is shown below:

  ./install.sh -j 8 -d /home/jmaebe/private/setupspec2006/specinst/ \
  -c armgcc436 \
  -t /home/jmaebe/toolchains/diablo-gcc-4.3.6-binutils-2.18-eglibc-2.11-arm \
  -p arm-unknown-linux-gnueabi

Note that the log files generated during the installation of SPEC2006 will
contain errors, such as the inability to install the SPEC tools at the end of
the specinstall.log file. You can ignore these, as they are expected. Unless
the install.sh script aborts, everything should be fine.

Building
========

Once installed, you will probably want to build SPEC2006. The instructions on
how to do this are printed at the end of the install.sh script's execution:

  cd /home/jmaebe/private/setupspec2006/specinst
  source shrc
  runspec -a build -c armgcc436 --size=test all >specbuild.log 2>&1

This will compile all the SPEC CPU2006 benchmarks using the selected toolchain
in the "Install" step.

Setup
=====

Once the SPEC benchmarks have been compiled, they can be set up for testing
via the ../common/regression-main/regression.py script by using the
./spec2regression.sh script. Again, executing this script without parameters
will show a help screen. An example usage is shown below:

  ./spec2regression.sh -s "-p 914 -c blowfish jmaebe@drone" -r "spec2006" \
  -p /home/jmaebe/private/setupspec2006/specinst \
  -b build_base_armgcc436-nn.0000 \
  -d /home/jmaebe/private/diablo/regression/arm/spec2006 \
  -a arm-softfp \
  -e little

Look at ../common/regression-main/README.txt for information on how to use the
regression.py script.
