#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/dryer.jpg.out $testdir/dryer.jpg.out | egrep -v "^specdiff run completed$" > $testdir/dryer.jpg.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/input.program.out $testdir/input.program.out | egrep -v "^specdiff run completed$" > $testdir/input.program.out.cmp
exitcode=0
for i in dryer.jpg.out input.program.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

