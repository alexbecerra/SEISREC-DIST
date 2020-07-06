#!/bin/bash

debug=""
convert_to=""

##################################################################################################################################
# DISPLAY HELP
#################################################################################################################################
function print_help() {
  printf "Uso: dist2dev.sh [opciones] <modo> \n"
  printf "    [-h]                  Muestra este mensaje de ayuda y termina.\n"
  printf "    [-d]                  Habilita los mensajes de debug.\n"
  printf "\nModos:\n"
  printf "       DIST: Convierte a la version DISTRIBUCION \n"
  printf "       DEV:  Convierte a la version DESARROLLO \n"
  exit 0
}

##################################################################################################################################
# PROMPT FOR REPODIR MANUALLY
#################################################################################################################################
function prompt_workdir() {
  local answered=""
  local done=""
  local continue
  local continue2

  printf "Directorio del repositorio no pudo ser encontrado automáticamente.\n"
  printf "Desea ingresarlo de forma manual? [S]í/[N]o \n"
  # Chance to exit without enterin repodir
  while [ -z "$done" ]; do
    if ! read -r continue; then
      printf "Error reading STDIN! Aborting...\n"
      exit 1
    elif [[ "$continue" =~ [sS].* ]]; then
      # if yes prompt for repodir
      done="yes"
      while [ -z "$answered" ]; do
      printf "Directorio donde se encuentra la carpeta SEISREC-DIST: \n"
      if ! read -r repodir; then
        printf "Error reading STDIN! Aborting...\n"
        exit 1
      fi
      printf "Es \"%s\" correcto? [S]í/[N]o/[C]ancelar\n" "$repodir"
        # Confirm input
        if ! read -r continue2; then
          printf "Error reading STDIN! Aborting...\n"
          exit 1
        elif [[ "$continue2" =~ [sS].* ]]; then
          answered="yes"
          return 0
        elif [[ "$continue2" =~ [nN].* ]]; then
          answered=""
        elif [[ "$continue2" =~ [cC].* ]]; then
          answered="no"
        else
          printf "\n[S]í/[N]o ?"
        fi
      done
    elif [[ "$continue" =~ [nN].* ]]; then
      done="no"
    else
      printf "\n[S]í/[N]o ?"
    fi
  done
  return 1
}

##################################################################################################################################
# GET WORKING DIRECTORY
#################################################################################################################################
# automatic search for repo directory assuming dist2dev resides in /SEISREC-DIST/scripts/
if [ -z "$repodir" ]; then
  repodir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  repodir=$(printf "%s" "$repodir" | sed -e "s/\/SEISREC-DIST.*//")
  #repodir is the immediate parent directory to SEISREC-DIST
fi

# if repodir found, source script utils
if [ -n "$repodir" ]; then
  export repodir
  workdir="$repodir/SEISREC-DIST"
  source "$workdir/scripts/script_utils.sh"
else
  if ! prompt_workdir; then
    printf "Error obteniendo el directorio de trabajo. Abortando...\n"
    exit 1
  fi
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

# Parse options
while getopts "dh" opt; do
  case ${opt} in
  d)
    debug="yes"
    ;;
  h)
    print_help
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
    # check for repository name to be sure were deleting the correct directory
    reponame=$(basename $(git rev-parse --show-toplevel))

    if [ -n "$debug" ]; then
      printf "Nombre del repositorio = %s\n" "$reponame"
    fi

    # Notify if everything's in order, delete directory anyway
    if [ "$reponame" == "SEISREC-DEV" ]; then
      printf "Se detecto el directorio SEISREC-DEV. Borrando...\n"
    else
      printf "Se detecto el directorio SEISREC-DEV, pero tiene el repositorio incorrecto. Borrando...\n"
    fi

    # Exit directory first
    if ! cd ..; then
        printf "Error tratando de salir de ./SEISREC-DEV!. Abortando...\n"
        exit 1
      fi
      printf "Removiendo SEISREC-DEV...\n"
      # remove with sudo, as git prevents user deleting repository files
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
    # check for repository name to be sure were deleting the correct directory
    reponame=$(basename $(git rev-parse --show-toplevel))
    if [ -n "$debug" ]; then
      printf "Nombre del repositorio = %s\n" "$reponame"
    fi

    # Check if SEISREC-DEV already present
    if [ "$reponame" == "SEISREC-DEV" ]; then
      printf "La estacion ya esta convertida a DEV!. Saliendo...\n"
      exit 1 # Exit if there's any funny business with the filesystem
    else
      # If there's some error with the repository, delete directory and start fresh
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
  # move into SEISREC-DIST
  printf "Accediendo a %s\n" "$workdir"
  if ! cd "$workdir"; then
    printf "Error tratando de acceder a SEISREC-DIST!\n"
    exit 1 # Exit if there's any funny business with the filesystem
  fi

  # Clone Directory
  printf "Clonando SEISREC-DEV...\n"
  if ! git clone https://github.com/alexbecerra/SEISREC-DEV.git; then
    printf "Error clonando ./SEISREC-DEV!\n"
    exit 1 # Exit if there's any funny business with the filesystem
  fi

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

# move back out to original directory
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