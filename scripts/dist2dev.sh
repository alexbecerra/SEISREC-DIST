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

cd "$HOME/SEISREC-DIST/SEISREC-DEV"

if ! git checkout --track origin/repos_refactor; then
  printf "Error switching branches!\n"
fi

cd $currdir