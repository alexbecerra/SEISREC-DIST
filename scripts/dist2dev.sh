#!/bin/bash

if [ -z "$repodir" ]; then
    repodir="$HOME/SEISREC/"
fi

if ! git clone https://github.com/alexbecerra/SEISREC-DEV.git "$HOME/SEISREC/DEV"; then
  printf "Error cloning into ./DEV!\n"
  exit 1
fi

currdir=$(pwd)

cd "$HOME/SEISREC/DEV"

if ! git checkout --track origin/repos_refactor; then
  printf "Error switching branches!\n"
fi
cd