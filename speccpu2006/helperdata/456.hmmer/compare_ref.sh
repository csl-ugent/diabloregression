#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.002 $refdir/nph3.out $testdir/nph3.out | egrep -v "^specdiff run completed$" > $testdir/nph3.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.002 $refdir/retro.out $testdir/retro.out | egrep -v "^specdiff run completed$" > $testdir/retro.out.cmp
exitcode=0
for i in nph3.out retro.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

