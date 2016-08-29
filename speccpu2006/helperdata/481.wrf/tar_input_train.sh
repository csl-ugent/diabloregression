#!/usr/bin/env bash
cd `dirname $0`
outfile=input_train.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/all/GENPARM.TBL input/all/LANDUSE.TBL input/all/SOILPARM.TBL input/all/VEGPARM.TBL input/all/wrf.in input/all/RRTM_DATA input/train/namelist.input input/train/wrfbdy_d01 input/train/wrfinput_d01 do_runme_train.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|train\)/::" $inputfiles $inputdirs
