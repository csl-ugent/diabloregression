#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-0.eps $testdir/grid-0.eps | egrep -v "^specdiff run completed$" > $testdir/grid-0.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-1.eps $testdir/grid-1.eps | egrep -v "^specdiff run completed$" > $testdir/grid-1.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-2.eps $testdir/grid-2.eps | egrep -v "^specdiff run completed$" > $testdir/grid-2.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-3.eps $testdir/grid-3.eps | egrep -v "^specdiff run completed$" > $testdir/grid-3.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-4.eps $testdir/grid-4.eps | egrep -v "^specdiff run completed$" > $testdir/grid-4.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-5.eps $testdir/grid-5.eps | egrep -v "^specdiff run completed$" > $testdir/grid-5.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-6.eps $testdir/grid-6.eps | egrep -v "^specdiff run completed$" > $testdir/grid-6.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-7.eps $testdir/grid-7.eps | egrep -v "^specdiff run completed$" > $testdir/grid-7.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-8.eps $testdir/grid-8.eps | egrep -v "^specdiff run completed$" > $testdir/grid-8.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-0.gmv $testdir/solution-0.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-0.gmv.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-1.gmv $testdir/solution-1.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-1.gmv.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-2.gmv $testdir/solution-2.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-2.gmv.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-3.gmv $testdir/solution-3.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-3.gmv.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-4.gmv $testdir/solution-4.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-4.gmv.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-5.gmv $testdir/solution-5.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-5.gmv.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-6.gmv $testdir/solution-6.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-6.gmv.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-7.gmv $testdir/solution-7.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-7.gmv.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-8.gmv $testdir/solution-8.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-8.gmv.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-10.eps $testdir/grid-10.eps | egrep -v "^specdiff run completed$" > $testdir/grid-10.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/grid-9.eps $testdir/grid-9.eps | egrep -v "^specdiff run completed$" > $testdir/grid-9.eps.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/log $testdir/log | egrep -v "^specdiff run completed$" > $testdir/log.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-10.gmv $testdir/solution-10.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-10.gmv.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-07 $refdir/solution-9.gmv $testdir/solution-9.gmv | egrep -v "^specdiff run completed$" > $testdir/solution-9.gmv.cmp
exitcode=0
for i in grid-0.eps grid-1.eps grid-2.eps grid-3.eps grid-4.eps grid-5.eps grid-6.eps grid-7.eps grid-8.eps solution-0.gmv solution-1.gmv solution-2.gmv solution-3.gmv solution-4.gmv solution-5.gmv solution-6.gmv solution-7.gmv solution-8.gmv grid-10.eps grid-9.eps log solution-10.gmv solution-9.gmv ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

