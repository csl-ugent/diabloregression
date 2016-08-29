#!/usr/bin/env bash
cd `dirname $0`
outfile=input_train.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/train/stdin do_runme_train.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|train\)/::" $inputfiles $inputdirs
