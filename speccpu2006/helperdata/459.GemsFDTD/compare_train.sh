#!/bin/bash
refdir=$1
testdir=$2
spec_install_dir=VAR_SPEC_INSTALL_DIRECTORY
cd $spec_install_dir
source ./shrc
cd - > /dev/null
specperl $spec_install_dir/bin/specdiff -m -l 10 --abstol 1e-10 --reltol 1e-09 --obiwan $refdir/sphere_td.nft $testdir/sphere_td.nft | egrep -v "^specdiff run completed$" > $testdir/sphere_td.nft.cmp
exitcode=0
for i in sphere_td.nft ; do
  if [[ ! -f $testdir/$i ]]; then
    echo "Output file $i does not exist"
    exitcode=1
  elif [[ -s $testdir/$i.cmp ]]; then
    echo "Output file $i differs"
    exitcode=1
  fi
done
exit $exitcode

