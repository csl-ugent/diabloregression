#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.0001 --ignorecase $refdir/h2ocu2+.energy.out $testdir/h2ocu2+.energy.out | egrep -v "^specdiff run completed$" > $testdir/h2ocu2+.energy.out.cmp
exitcode=0
for i in h2ocu2+.energy.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

