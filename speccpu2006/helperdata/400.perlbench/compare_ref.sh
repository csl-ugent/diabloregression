#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/checkspam.2500.5.25.11.150.1.1.1.1.out $testdir/checkspam.2500.5.25.11.150.1.1.1.1.out | egrep -v "^specdiff run completed$" > $testdir/checkspam.2500.5.25.11.150.1.1.1.1.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/diffmail.4.800.10.17.19.300.out $testdir/diffmail.4.800.10.17.19.300.out | egrep -v "^specdiff run completed$" > $testdir/diffmail.4.800.10.17.19.300.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/splitmail.1600.12.26.16.4500.out $testdir/splitmail.1600.12.26.16.4500.out | egrep -v "^specdiff run completed$" > $testdir/splitmail.1600.12.26.16.4500.out.cmp
exitcode=0
for i in checkspam.2500.5.25.11.150.1.1.1.1.out diffmail.4.800.10.17.19.300.out splitmail.1600.12.26.16.4500.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

