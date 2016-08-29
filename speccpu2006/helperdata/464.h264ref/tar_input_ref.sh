#!/usr/bin/env bash
cd `dirname $0`
outfile=input_ref.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/all/foreman_qcif.yuv input/all/leakybucketrate.cfg input/ref/foreman_ref_encoder_baseline.cfg input/ref/foreman_ref_encoder_main.cfg input/ref/sss.yuv input/ref/sss_encoder_main.cfg do_runme_ref.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|ref\)/::" $inputfiles $inputdirs
