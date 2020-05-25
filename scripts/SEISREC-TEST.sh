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

if [ -d "$dir" ]; then
TESTS=$(ls "$dir")

for t in $TESTS; do
  printf "Comenzando pruebas de placa %s...\n" "$(printf "%s" "$s" | sed -e "s/TEST_//")"
  if ! "$dir/$t"; then
    printf "Error en %s!\n" "$t"
  fi
  printf "\n"
done
else
  printf "No hay tests disponibles!\n"
fi