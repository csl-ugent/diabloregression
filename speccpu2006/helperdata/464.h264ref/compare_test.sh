#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 --cw --floatcompare $refdir/foreman_test_baseline_encodelog.out $testdir/foreman_test_baseline_encodelog.out | egrep -v "^specdiff run completed$" > $testdir/foreman_test_baseline_encodelog.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --binary --cw --floatcompare $refdir/foreman_test_baseline_leakybucketparam.cfg $testdir/foreman_test_baseline_leakybucketparam.cfg | egrep -v "^specdiff run completed$" > $testdir/foreman_test_baseline_leakybucketparam.cfg.cmp
exitcode=0
for i in foreman_test_baseline_encodelog.out foreman_test_baseline_leakybucketparam.cfg ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

