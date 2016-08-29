#!/usr/bin/env bash
cd `dirname $0`
outfile=input_test.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/all/foreman_qcif.yuv input/all/leakybucketrate.cfg input/test/foreman_test_encoder_baseline.cfg do_runme_test.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|test\)/::" $inputfiles $inputdirs
