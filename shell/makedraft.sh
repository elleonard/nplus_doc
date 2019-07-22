#!/bin/bash

if [ $# -lt 2 ]
then
  echo "usage: bash makedraft.sh template target"
  exit
fi

template=$1
target=$2

cp scaffolds/$template.md scaffolds/draft.md
hexo new draft $target
