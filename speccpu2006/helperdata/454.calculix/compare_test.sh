#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd -
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-09 --reltol 1e-09 --obiwan $refdir/SPECtestformatmodifier_z.txt $testdir/SPECtestformatmodifier_z.txt | egrep -v "^specdiff run completed$" > $testdir/SPECtestformatmodifier_z.txt.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-09 --reltol 1e-09 --obiwan $refdir/beampic.dat $testdir/beampic.dat | egrep -v "^specdiff run completed$" > $testdir/beampic.dat.cmp
exitcode=0
for i in SPECtestformatmodifier_z.txt beampic.dat ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode
