#!/bin/bash

# install_services.sh
#
# Utility for installing services and building distribution
# copies of the service units used in SEISREC system.
#

disable=""
install=""
re=""
debug=""
fileList=""
# Parse options
function print_help {
  printf "Usage: install_services.sh [options] <mode>\n"
  printf "    [-h]                  Display this help message.\n"
  printf "    [-f]                  File listing services to be built/installed\n"
  printf "    [-d]                  Debug Flag  \n"
  printf "\nModes:\n"
  printf "  DISABLE: stop and disable all services.\n"
  printf "  CLEAN: stop, disable and remove all links.\n"
  printf "  INSTALL: stop, disable, remove all links and install and reenable.\n"
  exit 0
}
while getopts ":hfd" opt; do
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
  \?)
    printf "Invalid Option: -%s" "$OPTARG" 1>&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

unset PARAM

while [ -n "$1" ]; do
  PARAM="${1,,}"
  if [ -n "$debug" ]; then
      printf "PARAM = %s\n" "$PARAM"
  fi
  case $PARAM in
  # DISABLE: stop and disable all services
  disable)
    disable="yes"
    break
    ;;
  # CLEAN: stop, disable and remove all links
  clean)
    disable="yes"
    re="yes"
    break
    ;;
  # INSTALL: stop, disable, remove all links and install the built versions then, enable them
  install)
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

if [ -z "$disable" ]; then
    print_help
fi

if [ -z "$repodir" ]; then
  repodir="$HOME"
fi

# Let the user know the script started
printf "install_services.sh - SEISREC services install utility\n"

# Print warning, this should be optional
printf "This script will stop all running SEISREC services. Continue? [Y]es/[N]o "
# Get answers
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
answered=""


# List all services & timers in the services directory
printf "Getting service list...\n"
if [ -n "$fileList" ]; then
  if [ -f "$fileList" ]; then
    services=$(cat "$fileList")
  else
    services=$(ls "$repodir/SEISREC/services/")
  fi
else
  services=$(ls "$repodir/SEISREC/services/")
fi

if [ -n "$debug" ]; then
  printf "services = %s\n" "$services"
fi

justservices=$(printf "%s " "$services" | grep ".*.service")
for s in $justservices; do
  temp=$(systemctl list-units --type=service | grep -o $s)
  if [ "$s" == "$temp" ]; then
    printf "Stopping & disabling %s...\n" "$s"
    if ! sudo systemctl stop "$s"; then
      printf "Error stopping %s!\n" "$s"
    fi
    if ! sudo systemctl disable "$s"; then
      printf "Error disabling %s!\n" "$s"
    fi
  fi
  unset temp
done

# If -r option is used, remove services
if [ -n "$re" ]; then
  printf "Removing installed service files...\n"
  for f in $services; do
    if [ -f "/etc/systemd/system/$f" ]; then
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

if [ ! -d "$repodir/SEISREC/unit/" ]; then
    printf "No unit executable directory! Aborting...\n"
    exit 1
fi

# Install services
for f in $justservices; do
  # if symlink exists => service already installed
  if [ ! -f "/etc/systemd/system/$f" ]; then
    # Install only if corresponding unit executable exists
    unitname=$(printf "%s" "$f" | sed -e "s/.service//")
    if [ -n "$(ls "$repodir/SEISREC/unit/" | grep "$unitname")" ]; then
      printf "Installing %s...\n" "$f"
      # Create symlink to service in /etc/systemd/system/
      if ! sudo ln -s "$repodir/SEISREC/services/$f" "/etc/systemd/system/"; then
        printf "Error creating symlink for %s! Skipping...\n" "$f"
        continue
      fi
    else
      printf "No corresponding unit executable! Skipping...\n"
      continue
    fi

    # Enable service with systemctl
    if ! sudo systemctl enable "$f"; then
      printf "Error installing %s! Skipping...\n" "$f"
      continue
    fi
  else
    # if already installed, notify and abort
    printf "%s already installed! Use -r for removal. Aborting...\n" "$f"
    exit 1
  fi

  if ! sudo systemctl start "$f"; then
      printf "Error starting %s! Skipping...\n" "$f"
      continue
  fi
done
fi

printf "Service unit installation successful!\n"

