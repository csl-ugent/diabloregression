#!/usr/bin/env bash
cd `dirname $0`
outfile=input_train.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/train/arb.tst input/train/arend.tst input/train/arion.tst input/train/atari_atari.tst input/train/blunder.tst input/train/buzco.tst input/train/nicklas2.tst input/train/nicklas4.tst do_runme_train.sh"
inputdirs=" input/all/games input/all/golois"
tar cjf $outfile --transform="s:^input/\(all\|train\)/::" $inputfiles $inputdirs
