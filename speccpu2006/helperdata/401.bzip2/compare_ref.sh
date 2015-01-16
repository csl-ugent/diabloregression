#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/chicken.jpg.out $testdir/chicken.jpg.out | egrep -v "^specdiff run completed$" > $testdir/chicken.jpg.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/input.combined.out $testdir/input.combined.out | egrep -v "^specdiff run completed$" > $testdir/input.combined.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/input.program.out $testdir/input.program.out | egrep -v "^specdiff run completed$" > $testdir/input.program.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/input.source.out $testdir/input.source.out | egrep -v "^specdiff run completed$" > $testdir/input.source.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/liberty.jpg.out $testdir/liberty.jpg.out | egrep -v "^specdiff run completed$" > $testdir/liberty.jpg.out.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 $refdir/text.html.out $testdir/text.html.out | egrep -v "^specdiff run completed$" > $testdir/text.html.out.cmp
exitcode=0
for i in chicken.jpg.out input.combined.out input.program.out input.source.out liberty.jpg.out text.html.out ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

