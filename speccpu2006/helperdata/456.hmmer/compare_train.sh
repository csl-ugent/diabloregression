#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.002 $refdir/leng100.out $testdir/leng100.out | egrep -v "^specdiff run completed$" > $testdir/leng100.out.cmp
exitcode=0
for i in leng100.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode
