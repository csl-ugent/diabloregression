#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --reltol 0.001 $refdir/BigLakes1024.out $testdir/BigLakes1024.out | egrep -v "^specdiff run completed$" > $testdir/BigLakes1024.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --reltol 0.001 $refdir/rivers1.out $testdir/rivers1.out | egrep -v "^specdiff run completed$" > $testdir/rivers1.out.cmp
exitcode=0
for i in BigLakes1024.out rivers1.out ; do
  if [[ ! -f $testdir/$i ]]; then
    echo "Output file $i does not exist"
    exitcode=1
  elif [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

