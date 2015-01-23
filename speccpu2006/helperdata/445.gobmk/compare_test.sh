#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/capture.out $testdir/capture.out | egrep -v "^specdiff run completed$" > $testdir/capture.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/connect.out $testdir/connect.out | egrep -v "^specdiff run completed$" > $testdir/connect.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/connect_rot.out $testdir/connect_rot.out | egrep -v "^specdiff run completed$" > $testdir/connect_rot.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/connection.out $testdir/connection.out | egrep -v "^specdiff run completed$" > $testdir/connection.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/connection_rot.out $testdir/connection_rot.out | egrep -v "^specdiff run completed$" > $testdir/connection_rot.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/cutstone.out $testdir/cutstone.out | egrep -v "^specdiff run completed$" > $testdir/cutstone.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/dniwog.out $testdir/dniwog.out | egrep -v "^specdiff run completed$" > $testdir/dniwog.out.cmp
exitcode=0
for i in capture.out connect.out connect_rot.out connection.out connection_rot.out cutstone.out dniwog.out ; do
  if [[ ! -f $testdir/$i ]]; then
    echo "Output file $i does not exist"
    exitcode=1
  elif [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

