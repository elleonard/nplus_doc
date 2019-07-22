#!/bin/bash

if [ $# -lt 2 ]
then
  echo "usage: bash publishdraft.sh draft path"
  exit
fi

hexo publish post $1
mv source/_posts/$1 $2$1
mv source/_posts/$1.md $2$1.md
