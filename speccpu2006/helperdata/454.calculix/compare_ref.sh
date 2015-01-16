#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-09 --reltol 1e-09 --obiwan $refdir/SPECtestformatmodifier_z.txt $testdir/SPECtestformatmodifier_z.txt | egrep -v "^specdiff run completed$" > $testdir/SPECtestformatmodifier_z.txt.cmp
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-09 --reltol 1e-09 --obiwan $refdir/hyperviscoplastic.dat $testdir/hyperviscoplastic.dat | egrep -v "^specdiff run completed$" > $testdir/hyperviscoplastic.dat.cmp
exitcode=0
for i in SPECtestformatmodifier_z.txt hyperviscoplastic.dat ; do
  if [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

