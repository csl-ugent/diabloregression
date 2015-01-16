#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-06 --reltol 1e-05 $refdir/omnetpp.log $testdir/omnetpp.log | egrep -v "^specdiff run completed$" > $testdir/omnetpp.log.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-06 --reltol 1e-05 $refdir/omnetpp.sca $testdir/omnetpp.sca | egrep -v "^specdiff run completed$" > $testdir/omnetpp.sca.cmp
exitcode=0
for i in omnetpp.log omnetpp.sca ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

