#!/usr/bin/env bash
cd `dirname $0`
outfile=input_ref.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/ref/166.i input/ref/200.i input/ref/c-typeck.i input/ref/cp-decl.i input/ref/expr.i input/ref/expr2.i input/ref/g23.i input/ref/s04.i input/ref/scilab.i do_runme_ref.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|ref\)/::" $inputfiles $inputdirs
