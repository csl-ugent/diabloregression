#!/usr/bin/env bash
cd `dirname $0`
outfile=input_test.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/all/GENPARM.TBL input/all/LANDUSE.TBL input/all/SOILPARM.TBL input/all/VEGPARM.TBL input/all/wrf.in input/all/RRTM_DATA input/test/namelist.input input/test/wrfbdy_d01 input/test/wrfinput_d01 do_runme_test.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|test\)/::" $inputfiles $inputdirs
