#!/usr/bin/env bash
cd `dirname $0`
outfile=input_train.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/train/an406-fcaw-b.raw input/train/ctlfile input/train/an407-fcaw-b.raw input/train/ctlfile input/train/an408-fcaw-b.raw input/train/ctlfile input/train/an409-fcaw-b.raw input/train/ctlfile input/train/an410-fcaw-b.raw input/train/ctlfile input/train/args.an4 input/train/ctlfile input/train/beams.dat input/train/ctlfile do_runme_train.sh"
inputdirs=" input/all/model"
tar cjf $outfile --transform="s:^input/\(all\|train\)/::" $inputfiles $inputdirs
