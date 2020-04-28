#!/bin/bash

debug=''
choice=""
done=""
function print_help() {
  printf "\n"
  printf "\n"
  printf "\n"
  printf "\n"
  printf "\n"
  printf "\n"
  printf "\n"
  exit 0
}

# Parse options
while getopts "dh" opt; do
  case ${opt} in
  d)
    debug="yes"
    ;;
  h)
    printf "Usage: SEISREC-config.sh [options]"
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

printf "SEISREC_config.sh - SEISREC configuration & setup utility\n"

if [ -z "$repodir" ]; then
  repodir="$HOME"
fi

while [ -z "$done" ]; do
  PS3='Selection: '
  options=("Configure Station" "Station Setup" "Help" "Quit")
  select opt in "${options[@]}"; do
    case $opt in
    "Configure Station")
      choice="${options[0]}"
      break
      ;;
    "Station Setup")
      choice="${options[1]}"
      break
      ;;
    "Help")
      print_help
      ;;
    "Quit")
      printf "Good bye!\n"
      exit 0
      ;;
    *) printf "invalid option %s\n" "$REPLY" ;;
    esac
  done

  if [ -n "$debug" ]; then
    printf "choice = %s\n" "$choice"
  fi

  case $choice in
  "Configure Station")
  if [ -f "$repodir/SEISREC-DIST/parameter" ]; then
    printf "No parameter file found! Please run station setup first!\n"
  else
    "$repodir/SEISREC-DIST/util/param-edit" -pth "$repodir/SEISREC-DIST/"
  fi
  ;;

  "Station Setup")


  "$repodir/SEISREC-DIST/scripts/install_services.sh INSTALL"


  if [ -n "$cfgeverywhere" ]; then
  # if symlink to SEISREC-config doesn't exist, create it
  if [ ! -h "$repodir/SEISREC-DIST/SEISREC-config" ]; then
    printf "Creating symlinks to SEISREC-config...\n"
    ln -s "$repodir/SEISREC-DIST/scripts/SEISREC-config.sh" "$repodir/SEISREC-DIST/SEISREC-config"
  fi

  # Check if ~/SEISREC is in PATH, if not, add it to PATH
  inBashrc=$(cat "$HOME/.bashrc" | grep 'SEISREC-DIST')
  inPath=$(printf "%s" "$PATH" | grep 'SEISREC-DIST')
  if [ -z "$inBashrc" ]; then
    if [ -z "$inPath" ]; then
      # Add it permanently to path
      printf "Adding ./SEISREC-DIST to PATH...\n"
      printf 'inPath=$(printf "$PATH"|grep "SEISREC-DIST")\n' >>~/.bashrc
      printf 'if [ -z "$inPath" ]\n' >>~/.bashrc
      printf 'then\n' >>~/.bashrc
      printf '  export PATH="~/SEISREC-DIST:$PATH"\n' >>~/.bashrc
      printf 'fi\n' >>~/.bashrc
    fi
  fi
  fi
  ;;
  esac
done
printf "Good bye!\n"
exit 0