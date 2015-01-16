#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/diffmail.2.550.15.24.23.100.out $testdir/diffmail.2.550.15.24.23.100.out | egrep -v "^specdiff run completed$" > $testdir/diffmail.2.550.15.24.23.100.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/perfect.b.3.out $testdir/perfect.b.3.out | egrep -v "^specdiff run completed$" > $testdir/perfect.b.3.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/scrabbl.out $testdir/scrabbl.out | egrep -v "^specdiff run completed$" > $testdir/scrabbl.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/splitmail.535.13.25.24.1091.out $testdir/splitmail.535.13.25.24.1091.out | egrep -v "^specdiff run completed$" > $testdir/splitmail.535.13.25.24.1091.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/suns.out $testdir/suns.out | egrep -v "^specdiff run completed$" > $testdir/suns.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/validate $testdir/validate | egrep -v "^specdiff run completed$" > $testdir/validate.cmp
exitcode=0
for i in diffmail.2.550.15.24.23.100.out perfect.b.3.out scrabbl.out splitmail.535.13.25.24.1091.out suns.out validate ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

