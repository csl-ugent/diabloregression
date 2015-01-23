#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/166.s $testdir/166.s | egrep -v "^specdiff run completed$" > $testdir/166.s.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/200.s $testdir/200.s | egrep -v "^specdiff run completed$" > $testdir/200.s.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/c-typeck.s $testdir/c-typeck.s | egrep -v "^specdiff run completed$" > $testdir/c-typeck.s.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/cp-decl.s $testdir/cp-decl.s | egrep -v "^specdiff run completed$" > $testdir/cp-decl.s.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/expr.s $testdir/expr.s | egrep -v "^specdiff run completed$" > $testdir/expr.s.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/expr2.s $testdir/expr2.s | egrep -v "^specdiff run completed$" > $testdir/expr2.s.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/g23.s $testdir/g23.s | egrep -v "^specdiff run completed$" > $testdir/g23.s.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/s04.s $testdir/s04.s | egrep -v "^specdiff run completed$" > $testdir/s04.s.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/scilab.s $testdir/scilab.s | egrep -v "^specdiff run completed$" > $testdir/scilab.s.cmp
exitcode=0
for i in 166.s 200.s c-typeck.s cp-decl.s expr.s expr2.s g23.s s04.s scilab.s ; do
  if [[ ! -f $testdir/$i ]]; then
    echo "Output file $i does not exist"
    exitcode=1
  elif [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

