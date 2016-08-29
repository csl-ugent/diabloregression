#!/usr/bin/env bash
cd `dirname $0`
outfile=input_ref.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/ref/13x13.tst input/ref/nngs.tst input/ref/score2.tst input/ref/trevorc.tst input/ref/trevord.tst do_runme_ref.sh"
inputdirs=" input/all/games input/all/golois"
tar cjf $outfile --transform="s:^input/\(all\|ref\)/::" $inputfiles $inputdirs
