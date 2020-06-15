#!/bin/bash

# install_services.sh
#
# Utility for installing services and building distribution
# copies of the service units used in SEISREC system.

disable=""
install=""
re=""
debug=""
fileList=""
disable=""
startstop=""
noprompt=""
unset PARAM

# Parse options
function print_help() {
  printf "Usage: install_services.sh [options] <mode>\n"
  printf "    [-h]                  Display this help message.\n"
  printf "    [-f]                  File listing services to be built/installed\n"
  printf "    [-d]                  Debug flag\n"
  printf "    [-n]                  No prompt\n"
  printf "\nModes:\n"
  printf "  START: start all services.\n"
  printf "  STOP: stop all services.\n"
  printf "  DISABLE: stop and disable all services.\n"
  printf "  CLEAN: stop, disable and remove all links.\n"
  printf "  INSTALL: stop, disable, remove all links, install and reenable all services.\n"
  exit 0
}
while getopts ":hfdn" opt; do
  case ${opt} in
  h)
    print_help
    ;;
  f)
    fileList="$OPTARG"
    ;;
  d)
    debug="yes"
    ;;
  n)
    noprompt="yes"
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
  # START: start all services
  start)
    startstop="start"
    break
    ;;
    # STOP: stop all services
  stop)
    startstop="stop"
    break
    ;;
  # DISABLE: stop and disable all services
  disable)
    startstop="stop"
    disable="yes"
    break
    ;;
  # CLEAN: stop, disable and remove all links
  clean)
    startstop="stop"
    disable="yes"
    re="yes"
    break
    ;;
  # INSTALL: stop, disable, remove all links and install the built versions then, enable them
  install)
    startstop="stop"
    disable="yes"
    re="yes"
    install="yes"
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

if [ -z "$repodir" ]; then
  if [ -n "$debug" ]; then
      printf "repodir empty!\n"
  fi
  repodir="$HOME"
fi

# Let the user know the script started
printf "install_services.sh - SEISREC services install utility\n"

if [ -n "$noprompt" ]; then
# Print warning, this should be optional
printf "This script will modify running SEISREC services. Continue? [Y]es/[N]o "
# Get answer
answered=""
while [ -z "$answered" ]; do
  if ! read -r continue; then
    printf "Error reading STDIN! Aborting...\n"
    exit 1
  elif [[ "$continue" =~ [yY].* ]]; then
    answered="yes"
    break
  elif [[ "$continue" =~ [nN].* ]]; then
    answered="no"
    break
  else
    printf "\nContinue? [Y]es/[N]o "
  fi
done

# Let the user know the script has started 100% for real now
if [ "$answered" == "yes" ]; then
  printf "Starting script...\n"
else
  printf "Exiting script!\n"
  exit 1
fi
fi
answered=""

if [ -n "$debug" ]; then
  printf "fileList = %s\n" "$fileList"
fi
# List all services & timers in the services directory
printf "Getting service list...\n"
if [ -n "$fileList" ]; then
  if [ -f "$fileList" ]; then
    services=$(cat "$fileList")
    if [ -n "$debug" ]; then
      printf "fileList is file!\n"
    fi
  else
    services=$(ls "$repodir/SEISREC-DIST/services/")
  fi
else
  services=$(ls "$repodir/SEISREC-DIST/services/")
fi

if [ -n "$debug" ]; then
  printf "services = %s\n" "$services"
fi

justservices=$(printf "%s " "$services" | grep ".*.service")
servicegraph=$(systemd-analyze blame)

ordered_services=()
for s in $servicegraph; do
  for t in $justservices; do
    if [ "$s" == "$t" ]; then
        if [ -n "$debug" ]; then
          printf "t = %s\n" "$t"
        fi
        ordered_services+=( "$t" )
    fi
  done
done

for t in $justservices; do
  matched="no"
  for s in $servicegraph; do
    if [ "$s" == "$t" ]; then
      matched="yes"
    fi
  done
  if [ "$matched" == "no" ]; then
    if [ -n "$debug" ]; then
      printf "t = %s\n" "$t"
    fi
    ordered_services+=( "$t" )
  fi
done

if [ -n "$debug" ]; then
  printf "ordered_services = "
  for f in "${ordered_services[@]}"; do
  printf "%s " "$f"
  printf "\n"
  done
fi

if [ -n "$startstop" ]; then
  tempstring=""
  case $startstop in
  "start")
      tempstring="Starting"
    ;;
  "stop")
      tempstring="Stopping"
    ;;
  esac
  for s in "${ordered_services[@]}"; do
    printf "%s %s\n" "$tempstring" "$s"
    if ! sudo systemctl "$startstop" "$s"; then
      printf "Error %s %s\n" "$tempstring" "$s"
    fi
  done
fi

if [ -n "$disable" ]; then
  for s in "${ordered_services[@]}"; do
    printf "Disabling %s...\n" "$s"
    if ! sudo systemctl disable "$s"; then
      printf "Error disabling %s!\n" "$s"
    fi
  done
fi

# If -r option is used, remove services
if [ -n "$re" ]; then
  printf "Removing installed service files...\n"
  for f in $services; do
    if [ -h "/etc/systemd/system/$f" ]; then
      printf "Removing %s...\n" "$f"
      if ! sudo rm "/etc/systemd/system/$f"; then
        printf "Error removing %s!\n" "$f"
      fi
    else
      if [ -n "$debug" ]; then
        printf "No previous %s install\n" "$f"
      fi
    fi
  done
fi

if [ -n "$install" ]; then
  # Let the user know what versions are installed
  printf "Installing services...\n"

  if [ ! -d "$repodir/SEISREC-DIST/unit/" ]; then
    printf "No unit executable directory! Aborting...\n"
    exit 1
  fi

  # Install services
  for f in $services; do
    # if symlink exists => service already installed
    if [ ! -f "/etc/systemd/system/$f" ]; then
      # Install only if corresponding unit executable exists
      unitname=$(printf "%s" "$f" | sed -e "s/.service//")
      if [ -z "$(ls "$repodir/SEISREC-DIST/unit/" | grep "$unitname")" ]; then
        printf "No corresponding unit executable for %s!!\n" "$f"
      fi

      if [ "$repodir" != "/home/pi" ]; then
        if [ -z "$(grep "=$repodir/SEISREC-DIST" "$repodir/SEISREC-DIST/services/$f")" ]; then
          if ! sed -i "s|/.*/SEISREC-DIST|$repodir/SEISREC-DIST|" "$repodir/SEISREC-DIST/services/$f"; then
            printf "Error setting unit executable paths in %s\n!" "$f"
          fi
        fi
      fi

      printf "Installing %s...\n" "$f"
      # Create symlink to service in /etc/systemd/system/
      if ! sudo ln -s "$repodir/SEISREC-DIST/services/$f" "/etc/systemd/system/"; then
        printf "Error creating symlink for %s! Skipping...\n" "$f"
        continue
      fi
    else
      # if already installed, notify and abort
      printf "%s already installed! Use -r for removal. Aborting...\n" "$f"
      exit 1
    fi
  done

  if ! sudo systemctl daemon-reload; then

    printf "Error reloading services! Aborting!...\n"
    exit 1
  fi
  # enable after all services have been installed

  for f in "${ordered_services[@]}"; do
    if ! sudo systemctl enable "$f"; then
      printf "Error enabling %s! Skipping...\n" "$f"
      continue
    fi
  done

  for f in "${ordered_services[@]}"; do
    if ! sudo systemctl start "$f"; then
      printf "Error starting %s! Skipping...\n" "$f"
      continue
    fi
  done

fi

printf "Service unit installation successful!\n"
