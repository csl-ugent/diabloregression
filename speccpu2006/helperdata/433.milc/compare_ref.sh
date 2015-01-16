#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 2e-07 --reltol 0.0001 $refdir/su3imp.out $testdir/su3imp.out | egrep -v "^specdiff run completed$" > $testdir/su3imp.out.cmp
exitcode=0
for i in su3imp.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

