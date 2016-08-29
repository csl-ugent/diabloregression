#!/usr/bin/env bash
cd `dirname $0`
outfile=input_test.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/test/capture.tst input/test/connect.tst input/test/connect_rot.tst input/test/connection.tst input/test/connection_rot.tst input/test/cutstone.tst input/test/dniwog.tst do_runme_test.sh"
inputdirs=" input/all/games input/all/golois"
tar cjf $outfile --transform="s:^input/\(all\|test\)/::" $inputfiles $inputdirs
