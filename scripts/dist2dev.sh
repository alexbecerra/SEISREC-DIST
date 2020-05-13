#!/bin/bash

# TODO: Add documentation & debug Messages


debug=""
convert_to=""

##################################################################################################################################
# GET WORKING DIRECTORY
# ################################################################################################################################
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

if [ -n "$(pwd | grep SEISREC-DIST)" ]; then
   printf "Current directory is inside SEISREC-DIST!\n"
   currdir="$repodir"
else
  currdir=$(pwd)
fi


function print_help() {
  printf "Usage: dist2dev.sh [DIST or DEV] \n"
  printf "       DIST: Convert to distribution version \n"
  printf "       DEV:  Convert to development version \n"
  exit 0
}
# Parse options
while getopts "dh" opt; do
  case ${opt} in
  d)
    debug="yes"
    ;;
  h)
    printf "Usage: dist2dev.sh [options]"
    printf "    [-h]                  Display this help message & exit.\n"
    printf "    [-d]                  Enable debug messages.\n"
    exit 0
    ;;
  \?)
    printf "Invalid Option: -%s" "$OPTARG" 1>&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

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
    printf "Invalid argument: -%s" "$PARAM" 1>&2
    exit 1
    ;;
  esac
  shift
done
unset PARAM

if [ -n "$debug" ]; then
  printf "\$(pwd) = %s\n" "$(pwd)"
  printf "currdir = %s\n" "$currdir"
fi

case $convert_to in
# START: start all services
"DIST")
  if [ -d "$workdir/SEISREC-DEV" ]; then
    printf "DEV directory already exists...\n"
    if ! cd "$workdir/SEISREC-DEV"; then
      printf "Error cd'ing into ./SEISREC-DEV!\n"
      exit 1
    fi
    reponame=$(basename $(git rev-parse --show-toplevel))
    if [ "$reponame" == "SEISREC-DEV" ]; then
      printf "SEISREC-DEV directory present. Deleting...\n"
    else
      printf "SEISREC-DEV directory present, but has wrong repository. Deleting...\n"
    fi
    if ! cd ..; then
        printf "Error cd'ing out of ./SEISREC-DEV! Aborting...\n"
        exit 1
      fi
      printf "Removing SEISREC-DEV...\n"
      if ! sudo rm -r "SEISREC-DEV"; then
        printf "Error removing ./SEISREC-DEV! Aborting...\n"
        exit 1
    fi
  fi

  ;;
"DEV")
  if [ -d "$workdir/SEISREC-DEV" ]; then
    printf "DEV directory already exists...\n"
    if ! cd "$workdir/SEISREC-DEV"; then
      printf "Error cd'ing into ./SEISREC-DEV!\n"
      exit 1
    fi
    reponame=$(basename $(git rev-parse --show-toplevel))
    if [ "$reponame" == "SEISREC-DEV" ]; then
      printf "Already converted to DEV! Exiting...\n"
      exit 1
    else
      printf "SEISREC-DEV directory present, but has wrong repository. Deleting...\n"
      if ! cd ..; then
        printf "Error cd'ing out of ./SEISREC-DEV! Aborting...\n"
        exit 1
      fi
      if ! sudo rm -r "SEISREC-DEV"; then
        printf "Error removing ./SEISREC-DEV! Aborting...\n"
        exit 1
      fi
    fi
  fi
  printf "cd'ing into %s\n" "$workdir"
  if ! cd "$workdir"; then
    printf "Error cd'ing into SEISREC-DIST!\n"
    exit 1
  fi

  if [ -d "$workdir/SEISREC-DEV" ]; then
    printf "DEV directory already exists..."
    if ! cd "./SEISREC-DEV"; then
      printf "Error cd'ing into ./SEISREC-DEV!\n"
      exit 1
    fi
    reponame=$(basename $(git rev-parse --show-toplevel))
    if [ "$reponame" == "SEISREC-DEV" ]; then
      printf "Already converted to DEV! Exiting...\n"
      exit 1
    else
      printf "SEISREC-DEV directory present, but has wrong repository. Deleting...\n"
      if ! cd .. ; then
        printf "Error cd'ing out of ./SEISREC-DEV! Aborting...\n"
        exit 1
      fi
      if ! sudo rm -r "SEISREC-DEV"; then
        printf "Error removing ./SEISREC-DEV! Aborting...\n"
        exit 1
      fi
    fi
  fi

  printf "Cloning SEISREC-DEV...\n"
  if ! git clone https://github.com/alexbecerra/SEISREC-DEV.git; then
    printf "Error cloning into ./SEISREC-DEV!\n"
    exit 1
  fi

  printf "cd'ing back into %s!\n" "$currdir"
  ;;
\?)
  printf "Invalid argument: -%s" "$PARAM" 1>&2
  exit 1
  ;;
esac

if [ -n "$debug" ]; then
  printf "currdir = %s\n" "$currdir"
fi

if ! cd $currdir; then
  printf "Error cd'ing back into %s!\n" "$currdir"
  exit 1
fi
unset PARAM
