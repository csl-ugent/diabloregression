#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 --reltol 0.001 --floatcompare $refdir/an4.log $testdir/an4.log | egrep -v "^specdiff run completed$" > $testdir/an4.log.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --reltol 0.0004 --floatcompare $refdir/considered.out $testdir/considered.out | egrep -v "^specdiff run completed$" > $testdir/considered.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --reltol 1e-06 --floatcompare $refdir/total_considered.out $testdir/total_considered.out | egrep -v "^specdiff run completed$" > $testdir/total_considered.out.cmp
exitcode=0
for i in an4.log considered.out total_considered.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

