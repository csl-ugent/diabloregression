#!/usr/bin/env bash
cd `dirname $0`
outfile=input_ref.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/all/GENPARM.TBL input/all/LANDUSE.TBL input/all/SOILPARM.TBL input/all/VEGPARM.TBL input/all/wrf.in input/all/RRTM_DATA input/ref/namelist.input input/ref/wrfbdy_d01 input/ref/wrfinput_d01 do_runme_ref.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|ref\)/::" $inputfiles $inputdirs
