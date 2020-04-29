#!/bin/bash

if [ -z "$repodir" ]; then
    repodir=$(find -P / -name "SEISREC-DIST" -print 2>/dev/null)
    if [ -z "$repodir" ]; then
      printf "Error finding repo directory!\n"
      repodir="$HOME"
    fi
fi

currdir=$(pwd)

printf "cd'ing into %s\n" "$repodir"
if ! cd "$repodir"; then
  printf "Error cd'ing into ./SEISREC-DEV!\n"
  exit 1
fi

printf "Cloning SEISREC-DEV...\n"
if ! git clone https://github.com/alexbecerra/SEISREC-DEV.git; then
  printf "Error cloning into ./SEISREC-DEV!\n"
  exit 1
fi

printf "cd'ing back into %s!\n" "$currdir"
if ! cd $currdir; then
  printf "Error cd'ing back into %s!\n" "$currdir"
  exit 1
fi