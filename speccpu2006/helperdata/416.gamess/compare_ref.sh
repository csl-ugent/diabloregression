#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.0001 --ignorecase $refdir/cytosine.2.out $testdir/cytosine.2.out | egrep -v "^specdiff run completed$" > $testdir/cytosine.2.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.0001 --ignorecase $refdir/h2ocu2+.gradient.out $testdir/h2ocu2+.gradient.out | egrep -v "^specdiff run completed$" > $testdir/h2ocu2+.gradient.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-05 --reltol 0.0001 --ignorecase $refdir/triazolium.out $testdir/triazolium.out | egrep -v "^specdiff run completed$" > $testdir/triazolium.out.cmp
exitcode=0
for i in cytosine.2.out h2ocu2+.gradient.out triazolium.out ; do
  if [[ ! -f $testdir/$i ]]; then
    echo "Output file $i does not exist"
    exitcode=1
  elif [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

