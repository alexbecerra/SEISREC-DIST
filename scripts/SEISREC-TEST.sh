#!/bin/bash

if [ -z "$repodir" ]; then
  repodir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  repodir=$(printf "%s" "$repodir" | sed -e "s/\/SEISREC-DIST.*//")
fi

if [ -n "$repodir" ]; then
  export repodir
  workdir="$repodir/SEISREC-DIST"
  source "$workdir/scripts/script_utils.sh"
else
  printf "Error getting working directory! Aborting...\n"
  exit 1
fi

dir="$repodir/SEISREC-DIST/TEST"

# TODO: Update code & generalize for all TESTS in /TEST/
echo " "
echo "Comenzando pruebas de placa ACC355"
sudo "$dir/TEST_ACC355"
echo " "
echo "Comenzando pruebas de placa TIMING"
sudo "$dir/TEST_TIMING"
