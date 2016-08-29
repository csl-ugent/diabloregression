#!/usr/bin/env bash
cd `dirname $0`
outfile=input_train.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/all/cpu2006_mhonarc.rc input/all/diffmail.pl input/all/splitmail.pl input/train/WORDS input/train/dictionary input/train/diffmail.in input/train/perfect.in input/train/perfect.pl input/train/scrabbl.in input/train/scrabbl.pl input/train/splitmail.in input/train/suns.pl do_runme_train.sh"
inputdirs=" input/all/lib input/all/rules"
tar cjf $outfile --transform="s:^input/\(all\|train\)/::" $inputfiles $inputdirs
