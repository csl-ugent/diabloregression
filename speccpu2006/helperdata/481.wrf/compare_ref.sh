#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 0.01 --reltol 0.05 $refdir/rsl.out.0000 $testdir/rsl.out.0000 | egrep -v "^specdiff run completed$" > $testdir/rsl.out.0000.cmp
exitcode=0
for i in rsl.out.0000 ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode
