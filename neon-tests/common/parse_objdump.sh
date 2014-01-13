#!/bin/bash

# convert pre-ual mnemonics to ual equivalents
awk 'NR==FNR {a[$1]=$2;next} {for ( i in a) gsub(i,a[i])}1' $(dirname $0)/preual-to-ual.list "$1" > .temp
mv .temp "$1"

# cat "$1" | grep -Ein "^Disassembly of section" | sed 's/:/ /g' | while read line
# do
#   linenumber=$(echo "$line" | cut -f 1 -d' ')
#   sectionname=$(echo "$line" | cut -f 5 -d' ')
#   sectionnumber=$(../../binutils/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi-readelf -S "$2" | grep -F "$sectionname" | grep -Eo "[0-9]+" | head -n 1)

#   sed -e "$linenumber s/\$/ SECTIONID=$sectionnumber/" < "$1" > .temp
#   rm "$1"
#   mv .temp "$1"
# done
