#!/usr/bin/env bash
cd `dirname $0`
outfile=input_ref.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/all/cpu2006_mhonarc.rc input/all/diffmail.pl input/all/splitmail.pl input/ref/checkspam.in input/ref/checkspam.pl input/ref/diffmail.in input/ref/splitmail.in do_runme_ref.sh"
inputdirs=" input/all/lib input/all/rules"
tar cjf $outfile --transform="s:^input/\(all\|ref\)/::" $inputfiles $inputdirs
