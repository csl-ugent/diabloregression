#!/usr/bin/env bash
cd `dirname $0`
outfile=input_ref.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/ref/stdin do_runme_ref.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|ref\)/::" $inputfiles $inputdirs
