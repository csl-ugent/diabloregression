#!/usr/bin/env bash
cd `dirname $0`
outfile=input_ref.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/ref/cytosine.2.config input/ref/cytosine.2.inp input/ref/h2ocu2+.gradient.config input/ref/h2ocu2+.gradient.inp input/ref/triazolium.config input/ref/triazolium.inp do_runme_ref.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|ref\)/::" $inputfiles $inputdirs
