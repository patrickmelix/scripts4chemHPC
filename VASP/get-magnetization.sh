#!/bin/bash
set -e


readarray -d '' array < <(find . -maxdepth 2 -name "OUTCAR" -print0 | sort -z)
#echo "${array[@]}"

for f in "${array[@]}"
do
      echo $f
      grep 'magnet' $f | tail -2
done

