#!/usr/bin/env bash
cd `dirname $0`
outfile=input_test.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/test/an406-fcaw-b.raw input/test/ctlfile input/test/an407-fcaw-b.raw input/test/ctlfile input/test/args.an4 input/test/ctlfile input/test/beams.dat input/test/ctlfile do_runme_test.sh"
inputdirs=" input/all/model"
tar cjf $outfile --transform="s:^input/\(all\|test\)/::" $inputfiles $inputdirs
