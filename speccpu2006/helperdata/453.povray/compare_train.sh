#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 0 --reltol 5e-05 $refdir/SPEC-benchmark.log $testdir/SPEC-benchmark.log | egrep -v "^specdiff run completed$" > $testdir/SPEC-benchmark.log.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 0 --reltol 5e-05 --skiptol 50 --binary $refdir/SPEC-benchmark.tga $testdir/SPEC-benchmark.tga | egrep -v "^specdiff run completed$" > $testdir/SPEC-benchmark.tga.cmp
exitcode=0
for i in SPEC-benchmark.log SPEC-benchmark.tga ; do
  if [[ ! -f $testdir/$i ]]; then
    echo "Output file $i does not exist"
    exitcode=1
  elif [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

