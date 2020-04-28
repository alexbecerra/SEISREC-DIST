#!/bin/bash

if [ -z "$repodir" ]; then
    repodir=$(sudo find -P "$HOME" -name "SEISREC-DIST")
fi

currdir=$(pwd)

if ! cd "$repodir"; then
  printf "Error cd'ing into ./SEISREC-DEV!\n"
  exit 1
fi

if ! git clone https://github.com/alexbecerra/SEISREC-DEV.git; then
  printf "Error cloning into ./SEISREC-DEV!\n"
  exit 1
fi

if ! cd $currdir; then
  printf "Error cd'ing back into %s!\n" "$currdir"
  exit 1
fi