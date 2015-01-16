#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --reltol 0.001 $refdir/lake.out $testdir/lake.out | egrep -v "^specdiff run completed$" > $testdir/lake.out.cmp
exitcode=0
for i in lake.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

