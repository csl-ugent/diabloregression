#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-16 $refdir/bwaves.out $testdir/bwaves.out | egrep -v "^specdiff run completed$" > $testdir/bwaves.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --reltol 0.015 $refdir/bwaves2.out $testdir/bwaves2.out | egrep -v "^specdiff run completed$" > $testdir/bwaves2.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --reltol 1e-06 $refdir/bwaves3.out $testdir/bwaves3.out | egrep -v "^specdiff run completed$" > $testdir/bwaves3.out.cmp
exitcode=0
for i in bwaves.out bwaves2.out bwaves3.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

