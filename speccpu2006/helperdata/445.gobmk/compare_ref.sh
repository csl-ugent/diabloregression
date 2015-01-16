#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/13x13.out $testdir/13x13.out | egrep -v "^specdiff run completed$" > $testdir/13x13.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/nngs.out $testdir/nngs.out | egrep -v "^specdiff run completed$" > $testdir/nngs.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/score2.out $testdir/score2.out | egrep -v "^specdiff run completed$" > $testdir/score2.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/trevorc.out $testdir/trevorc.out | egrep -v "^specdiff run completed$" > $testdir/trevorc.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/trevord.out $testdir/trevord.out | egrep -v "^specdiff run completed$" > $testdir/trevord.out.cmp
exitcode=0
for i in 13x13.out nngs.out score2.out trevorc.out trevord.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

