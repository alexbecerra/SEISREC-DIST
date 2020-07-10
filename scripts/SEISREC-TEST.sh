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
  printf "¡Error obteniendo el directorio de trabajo!. Abortando ...\n"
  exit 1
fi

dir="$repodir/SEISREC-DIST/TEST"

if [ -d "$dir" ]; then
TESTS=$(ls "$dir")

for t in $TESTS; do
  printf "Comenzando pruebas de placa %s ...\n" "$(printf "%s" "$t" | sed -e "s/TEST_//")"
  if ! sudo "$dir/$t"; then
    printf "¡Error en %s!.\n" "$t"
  fi
  printf "\n"
done
else
  printf "¡No hay pruebas disponibles!.\n"
fi