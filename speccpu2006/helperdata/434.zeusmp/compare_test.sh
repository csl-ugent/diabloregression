#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 0.001 --reltol 0.001 $refdir/tsl000aa $testdir/tsl000aa | egrep -v "^specdiff run completed$" > $testdir/tsl000aa.cmp
exitcode=0
for i in tsl000aa ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

