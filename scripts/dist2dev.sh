#!/bin/bash

debug=""
convert_to=""

# TODO [2]: Documentar mas el codigo

##################################################################################################################################
# DISPLAY HELP
#################################################################################################################################
function print_help() {
  printf "Uso: dist2dev.sh [DIST, DEV] \n"
  printf "       DIST: Convierte a la version DISTRIBUCION \n"
  printf "       DEV:  Convierte a la version DESARROLLO \n"
  exit 0
}

##################################################################################################################################
# GET WORKING DIRECTORY
#################################################################################################################################
if [ -z "$repodir" ]; then
  repodir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  repodir=$(printf "%s" "$repodir" | sed -e "s/\/SEISREC-DIST.*//")
fi

if [ -n "$repodir" ]; then
  export repodir
  workdir="$repodir/SEISREC-DIST"
  source "$workdir/scripts/script_utils.sh"
else
  # TODO [2]: Agregar posibilidad de ingresar el directorio manualmente, luego, salir.
  printf "Error obteniendo el directorio de trabajo. Abortando...\n"
  exit 1
fi

if [ -n "$debug" ]; then
  printf "Directorio = %s\n" "$workdir"
fi

# If im in the directory im going to delete then bail out
if [ -n "$(pwd | grep SEISREC-DEV)" ]; then
  printf "El directorio actual esta dentro de SEISREC-DEV!\n"
  currdir="$workdir"
else
  currdir=$(pwd)
fi

# TODO [4]: Quizas, para no confundir, agregar la opcion -t donde se indique si es dev o dist, asi todo queda dentro de este getopts
# Parse options
while getopts "dh" opt; do
  case ${opt} in
  d)
    debug="yes"
    ;;
  h)
    # TODO [5]: Corregir esto, pues es diferente a la descripcion de print_help()
    printf "Uso: dist2dev.sh [opciones]"
    printf "    [-h]                  Muestra este mensaje de ayuda y termina.\n"
    printf "    [-d]                  Habilita los mensajes de debug.\n"
    exit 0
    ;;
  \?)
    printf "Opcion invalida: -%s" "$OPTARG" 1>&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

# Parse arguments
while [ -n "$1" ]; do
  PARAM="${1,,}"
  if [ -n "$debug" ]; then
    printf "PARAM = %s\n" "$PARAM"
  fi
  if [ -z "$PARAM" ]; then
    print_help
  fi
  case $PARAM in
  "dist")
    convert_to="DIST"
    break
    ;;
  "dev")
    convert_to="DEV"
    break
    ;;
  "help")
    print_help
    break
    ;;
  \?)
    printf "Argumento invalido: -%s" "$PARAM" 1>&2
    exit 1
    ;;
  esac
  shift
done
unset PARAM

if [ -n "$debug" ]; then
  printf "\$(pwd) = %s\n" "$(pwd)"
  printf "Directorio actual = %s\n" "$currdir"
fi

case $convert_to in
# If converting to DIST, delete DEV directory safely
"DIST")
  if [ -d "$workdir/SEISREC-DEV" ]; then
    printf "El directorio DEV ya existe...\n"
    if ! cd "$workdir/SEISREC-DEV"; then
      printf "Error tratando de acceder a ./SEISREC-DEV!\n"
      exit 1
    fi
    reponame=$(basename $(git rev-parse --show-toplevel))

    if [ -n "$debug" ]; then
      printf "Nombre del repositorio = %s\n" "$reponame"
    fi

    if [ "$reponame" == "SEISREC-DEV" ]; then
      printf "Se detecto el directorio SEISREC-DEV. Borrando...\n"
    else
      printf "Se detecto el directorio SEISREC-DEV, pero tiene el repositorio incorrecto. Borrando...\n"
    fi
    if ! cd ..; then
        printf "Error tratando de salir de ./SEISREC-DEV!. Abortando...\n"
        exit 1
      fi
      printf "Removiendo SEISREC-DEV...\n"
      if ! sudo rm -r "SEISREC-DEV"; then
        printf "Error al remover ./SEISREC-DEV!. Abortando...\n"
        exit 1
    fi
  fi

  ;;
"DEV")
  # in converting to DEV, check if directory structure is broken, then clone.
  if [ -d "$workdir/SEISREC-DEV" ]; then
    printf "Directorio DEV ya existe...\n"
    if ! cd "$workdir/SEISREC-DEV"; then
      printf "Error tratando de acceder a ./SEISREC-DEV!\n"
      exit 1
    fi
    reponame=$(basename $(git rev-parse --show-toplevel))
    if [ -n "$debug" ]; then
      printf "Nombre del repositorio = %s\n" "$reponame"
    fi

    if [ "$reponame" == "SEISREC-DEV" ]; then
      printf "La estacion ya esta convertida a DEV!. Saliendo...\n"
      exit 1 # Exit if there's any funny business with the filesystem
    else
      printf "Se detecto el directorio SEISREC-DEV, pero tiene el repositorio incorrecto. Borrando...\n"
      if ! cd ..; then
        printf "Error tratando de salir de ./SEISREC-DEV!. Abortando...\n"
        exit 1 # Exit if there's any funny business with the filesystem
      fi
      if ! sudo rm -r "SEISREC-DEV"; then
        printf "Error al remover ./SEISREC-DEV!. Abortando...\n"
        exit 1 # Exit if there's any funny business with the filesystem
      fi
    fi
  fi
  printf "Accediendo a %s\n" "$workdir"
  if ! cd "$workdir"; then
    printf "Error tratando de acceder a SEISREC-DIST!\n"
    exit 1 # Exit if there's any funny business with the filesystem
  fi

  if [ -d "$workdir/SEISREC-DEV" ]; then
    printf "Directorio DEV ya existe...\n"
    if ! cd "./SEISREC-DEV"; then
      printf "Error tratando de acceder a ./SEISREC-DEV!\n"
      exit 1 # Exit if there's any funny business with the filesystem
    fi
    reponame=$(basename $(git rev-parse --show-toplevel))
    if [ -n "$debug" ]; then
      printf "Nombre del repositorio = %s\n" "$reponame"
    fi

    if [ "$reponame" == "SEISREC-DEV" ]; then
      printf "La estacion ya esta convertida a DEV!. Saliendo...\n"
      exit 1
    else
      printf "Se detecto el directorio SEISREC-DEV, pero tiene el repositorio incorrecto. Borrando...\n"
      if ! cd "$workdir" ; then
        printf "Error cd'ing out of ./SEISREC-DEV! Aborting...\n"
        exit 1 # Exit if there's any funny business with the filesystem
      fi
      if ! sudo rm -r "SEISREC-DEV"; then
        printf "Error al remover ./SEISREC-DEV!. Abortando...\n"
        exit 1 # Exit if there's any funny business with the filesystem
      fi
    fi
  fi

  printf "Clonando SEISREC-DEV...\n"
  if ! git clone https://github.com/alexbecerra/SEISREC-DEV.git; then
    printf "Error clonando ./SEISREC-DEV!\n"
    exit 1 # Exit if there's any funny business with the filesystem
  fi

  printf "Error volviendo a %s!\n" "$currdir"
  ;;
\?)
  printf "Argumento invalido: -%s" "$PARAM" 1>&2
  exit 1
  ;;
esac

if [ -n "$debug" ]; then
  printf "\$(pwd) = %s\n" "$(pwd)"
  printf "Directorio actual = %s\n" "$currdir"
fi

if ! cd "$currdir"; then
  printf "Error volviendo a %s!\n" "$currdir"
  exit 1
fi

if [ -n "$debug" ]; then
  printf "\$(pwd) = %s\n" "$(pwd)"
  printf "Directorio actual = %s\n" "$currdir"
fi

unset PARAM

exit 0