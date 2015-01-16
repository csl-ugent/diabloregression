#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 --reltol 0.001 $refdir/BigLakes2048.out $testdir/BigLakes2048.out | egrep -v "^specdiff run completed$" > $testdir/BigLakes2048.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --reltol 0.001 $refdir/rivers.out $testdir/rivers.out | egrep -v "^specdiff run completed$" > $testdir/rivers.out.cmp
exitcode=0
for i in BigLakes2048.out rivers.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

