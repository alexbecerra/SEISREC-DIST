#!/bin/bash
# TODO: Complete script

debug="yes"

convert_to=""
if [ -z "$repodir" ]; then
  repodir="$HOME"
fi
workdir="$repodir/SEISREC-DIST"

source "$workdir/scripts/script_utils.sh"

function print_help() {
  printf "Usage: dist2dev.sh [DIST or DEV] \n"
  printf "       DIST: Convert to distribution version \n"
  printf "       DEV:  Convert to development version \n"
  exit 0
}

while [ -n "$1" ]; do
  PARAM="${1,,}"
  if [ -n "$debug" ]; then
    printf "PARAM = %s\n" "$PARAM"
  fi
  if [ -z "$PARAM" ]; then
    print_help
  fi
  case $PARAM in
  # START: start all services
  "dist")
    convert_to="DIST"
    break
    ;;
    # STOP: stop all services
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

if [ -z "$distdir" ]; then
  printf "Searching for directory.\n"
  distdir=$(find -P / -name "SEISREC-DIST" -print 2>/dev/null)
  if [ -z "$distdir" ]; then
    printf "Error finding repo directory!\n"
    distdir="$repodir/SEISREC-DIST"
  fi
fi

if [ -n "$debug" ]; then
  printf "distdir = %s\n" "$distdir"
fi

currdir=$(pwd)

if [ -d "$distdir/SEISREC-DEV" ]; then
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
    if ! cd ".."; then
      printf "Error cd'ing out of ./SEISREC-DEV! Aborting...\n"
      exit 1
    fi
    if ! sudo rm -r "SEISREC-DEV"; then
      printf "Error removing ./SEISREC-DEV! Aborting...\n"
      exit 1
    fi
  fi
fi

case $convert_to in
# START: start all services
"DIST") ;;

"DEV")
  printf "cd'ing into %s\n" "$distdir"
  if ! cd "$distdir"; then
    printf "Error cd'ing into SEISREC-DIST!\n"
    exit 1
  fi

  if [ -d "$distdir/SEISREC-DEV" ]; then
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
      if ! cd ".."; then
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
  if ! cd $currdir; then
    printf "Error cd'ing back into %s!\n" "$currdir"
    exit 1
  fi
  ;;
\?)
  printf "Invalid argument: -%s" "$PARAM" 1>&2
  exit 1
  ;;
esac

unset PARAM
