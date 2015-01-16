#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/arb.out $testdir/arb.out | egrep -v "^specdiff run completed$" > $testdir/arb.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/arend.out $testdir/arend.out | egrep -v "^specdiff run completed$" > $testdir/arend.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/arion.out $testdir/arion.out | egrep -v "^specdiff run completed$" > $testdir/arion.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/atari_atari.out $testdir/atari_atari.out | egrep -v "^specdiff run completed$" > $testdir/atari_atari.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/blunder.out $testdir/blunder.out | egrep -v "^specdiff run completed$" > $testdir/blunder.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/buzco.out $testdir/buzco.out | egrep -v "^specdiff run completed$" > $testdir/buzco.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/nicklas2.out $testdir/nicklas2.out | egrep -v "^specdiff run completed$" > $testdir/nicklas2.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/nicklas4.out $testdir/nicklas4.out | egrep -v "^specdiff run completed$" > $testdir/nicklas4.out.cmp
exitcode=0
for i in arb.out arend.out arion.out atari_atari.out blunder.out buzco.out nicklas2.out nicklas4.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

