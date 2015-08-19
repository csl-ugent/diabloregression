#!/bin/bash

if [ "$#" -ne 1 ]; then
	echo "$0 <destination directory>"
	exit
fi

. $(cd `dirname $0` && pwd)/configuration.sh

target_directory=$1
check_empty "$target_directory" "please provide a destination directory"

spec_archive=/mnt/data/spec2006/speccommon.tar.bz2

tmp_file=`make_temp_suffix .tar.bz2`
download $spec_archive $tmp_file

create_dir_empty $target_directory
abs_target_directory=`cd $target_directory && pwd`

cd $abs_target_directory

echo "extracting data"
tar xf $tmp_file

echo "looking for files that need patching"
for f in `grep -rl "DIABLO_SPEC_TOOLS" .`; do
	if [ -n "`file $f | grep text`" ]; then
		echo "Patching file $f"
		sed -i "s:DIABLO_SPEC_TOOLS:${abs_target_directory}:g" $f
	fi
done

cd - > /dev/null

rm $tmp_file
