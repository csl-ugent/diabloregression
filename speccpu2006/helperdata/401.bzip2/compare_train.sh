#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/byoudoin.jpg.out $testdir/byoudoin.jpg.out | egrep -v "^specdiff run completed$" > $testdir/byoudoin.jpg.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/input.combined.out $testdir/input.combined.out | egrep -v "^specdiff run completed$" > $testdir/input.combined.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/input.program.out $testdir/input.program.out | egrep -v "^specdiff run completed$" > $testdir/input.program.out.cmp
exitcode=0
for i in byoudoin.jpg.out input.combined.out input.program.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

