#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 20 --reltol 0.0001 --obiwan $refdir/pds-50.mps.info $testdir/pds-50.mps.info | egrep -v "^specdiff run completed$" > $testdir/pds-50.mps.info.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.02 --obiwan $refdir/pds-50.mps.out $testdir/pds-50.mps.out | egrep -v "^specdiff run completed$" > $testdir/pds-50.mps.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 20 --reltol 0.0001 --obiwan $refdir/ref.mps.info $testdir/ref.mps.info | egrep -v "^specdiff run completed$" > $testdir/ref.mps.info.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.02 --obiwan $refdir/ref.out $testdir/ref.out | egrep -v "^specdiff run completed$" > $testdir/ref.out.cmp
exitcode=0
for i in pds-50.mps.info pds-50.mps.out ref.mps.info ref.out ; do
  if [[ ! -f $testdir/$i ]]; then
    echo "Output file $i does not exist"
    exitcode=1
  elif [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

