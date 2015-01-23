#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 20 --reltol 1 --obiwan $refdir/test.mps.info $testdir/test.mps.info | egrep -v "^specdiff run completed$" > $testdir/test.mps.info.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.0001 --obiwan $refdir/test.out $testdir/test.out | egrep -v "^specdiff run completed$" > $testdir/test.out.cmp
exitcode=0
for i in test.mps.info test.out ; do
  if [[ ! -f $testdir/$i ]]; then
    echo "Output file $i does not exist"
    exitcode=1
  elif [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

