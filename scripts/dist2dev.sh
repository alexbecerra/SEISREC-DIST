#!/bin/bash

if [ -z "$repodir" ]; then
    repodir="$HOME/SEISREC/"
fi

currdir=$(pwd)

cd "$HOME/SEISREC-DIST/"

if ! git clone https://github.com/alexbecerra/SEISREC-DEV.git; then
  printf "Error cloning into ./SEISREC-DEV!\n"
  exit 1
fi

cd $currdir