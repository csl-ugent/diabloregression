#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 20 --reltol 0.0001 --obiwan $refdir/pds-20.mps.info $testdir/pds-20.mps.info | egrep -v "^specdiff run completed$" > $testdir/pds-20.mps.info.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.02 --obiwan $refdir/pds-20.mps.out $testdir/pds-20.mps.out | egrep -v "^specdiff run completed$" > $testdir/pds-20.mps.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 20 --reltol 0.0001 --obiwan $refdir/train.mps.info $testdir/train.mps.info | egrep -v "^specdiff run completed$" > $testdir/train.mps.info.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.02 --obiwan $refdir/train.out $testdir/train.out | egrep -v "^specdiff run completed$" > $testdir/train.out.cmp
exitcode=0
for i in pds-20.mps.info pds-20.mps.out train.mps.info train.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

