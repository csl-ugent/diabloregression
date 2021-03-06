#!/usr/bin/env bash
cd `dirname $0`
outfile=input_train.tar.bz2
if [ -e $outfile ]; then
  exit 0
fi
inputfiles=" input/all/arrays.inc input/all/chars.inc input/all/colors.inc input/all/consts.inc input/all/crystal.ttf input/all/cyrvetic.ttf input/all/debug.inc input/all/finish.inc input/all/functions.inc input/all/glass.inc input/all/glass_old.inc input/all/golds.inc input/all/logo.inc input/all/math.inc input/all/metals.inc input/all/povlogo.ttf input/all/rad_def.inc input/all/rand.inc input/all/screen.inc input/all/shapes.inc input/all/shapes2.inc input/all/shapes_old.inc input/all/shapesq.inc input/all/skies.inc input/all/stage1.inc input/all/stars.inc input/all/stdcam.inc input/all/stdinc.inc input/all/stoneold.inc input/all/stones.inc input/all/stones1.inc input/all/stones2.inc input/all/strings.inc input/all/sunpos.inc input/all/textures.inc input/all/timrom.ttf input/all/transforms.inc input/all/woodmaps.inc input/all/woods.inc input/train/SPEC-benchmark-train.ini input/train/SPEC-benchmark-train.pov do_runme_train.sh"
inputdirs=""
tar cjf $outfile --transform="s:^input/\(all\|train\)/::" $inputfiles $inputdirs
