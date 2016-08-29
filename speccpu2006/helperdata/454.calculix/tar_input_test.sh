#!/usr/bin/env bash
cd `dirname $0`
outfile=input_test.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/test/beampic.inp do_runme_test.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|test\)/::" $inputfiles $inputdirs
