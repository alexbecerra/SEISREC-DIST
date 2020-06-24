#!/bin/bash

debug=''
choice=""
done=""
sta_type="DIST"
other_sta_type="DEV"

# Parse options first and foremost
while getopts "dh" opt; do
  case ${opt} in
  d)
    debug="yes" # Set debug as early as posible
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

##################################################################################################################################
# GET WORKING DIRECTORY - obtains directory where repo is stored
# ################################################################################################################################

# Get working directory from source directory of running script
if [ -z "$repodir" ]; then
  repodir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
  # remove SEISREC-DIST to obtain directory where repo is located
  repodir=$(printf "%s" "$repodir" | sed -e "s/\/SEISREC-DIST.*//")
fi

# if the directory is found, export variable for scripts that are called later
if [ -n "$repodir" ]; then
  if [ -n "$debug" ]; then
    printf "repodir = %s" "$repodir"
  fi
  export repodir
  workdir="$repodir/SEISREC-DIST"
  # workdir variable declared for convenience
  if [ -n "$debug" ]; then
    printf "workdir = %s" "$workdir"
  fi

  # Sourcing script_utils.sh for utility bash functions
  if source "$workdir/scripts/script_utils.sh"; then
    printf "Sourcing script_utils.sh...\n"
  else
    printf "Error sourcing script_utils.sh! Aborting...\n"
    exit 1
  fi
else
  printf "Error getting working directory! Aborting...\n"
  exit 1
fi

##################################################################################################################################
# PRINT HELP SECTION - function for printing help onscreen
# ################################################################################################################################
function print_help() {
  print_title "AYUDA - SEISREC-config.sh"
  under_construction
  # TODO: Write Help Section
  any_key
}

##################################################################################################################################
# CONFIGURE STATION PARAMS - function that calls util Param-edit for editing station parameters
# ################################################################################################################################
function configure_station() {
  local opts=()
  # specifying path to parameter file
  opts+=(-pth "$repodir/SEISREC-DIST/")
  # if debug print used options
  if [ -n "$debug" ]; then
    #if debug flag, call util param-edit with -debug
    opts+=(-debug)
    printf "opts = "
    for o in "${opts[@]}"; do
      printf "%s " "$o"
    done
    printf "\n"
  fi
  print_title "CONFIGURE STATION PARAMETERS - SEISREC-config.sh"
  "$repodir/SEISREC-DIST/util/util_paramedit" "${opts[@]}"
  any_key
}

##################################################################################################################################
# UPDATE SYSTEM SOFTWARE - updates to DIST and DEV software
# ################################################################################################################################
function update_station_software() {
  print_title "SYSTEM UPDATE- SEISREC-config.sh"
  # sta_type variable must be defined
  if [ -z "$sta_type" ]; then
    printf "Station Type not defined!\n"
    exit 1
  fi

  local currdir=$(pwd)
  local answered=''
  local version=''
  local versionlist=''
  local selectedversion=''

  while [ -z "$answered" ]; do
    continue=""
    answered=""
    version=""
    print_title "SYSTEM UPDATE- SEISREC-config.sh"
    # Get last commit to SEISREC-DIST
    if [ -d "$workdir" ]; then
      if ! cd "$workdir"; then
        printf "Error cd'ing into %s\n" "$workdir"
        exit 1
      else
        if git log | head -5 >/dev/null 2>&1; then
          printf "SEISREC-DIST last commit to branch %s:\n\n" "$(git branch | grep "\*.*" | sed -e "s/* //")"
          printf "%s\n\n" "$(git log | head -5)"
          if git describe --tags >/dev/null 2>&1; then
            version=$(git describe --tags)
          fi
          if [ -n "$version" ]; then
            printf "\nSoftware Version: %s\n" "$version"
          fi
        else
          printf "Error getting git logs!\n"
        fi
      fi
    else
      printf "SEISREC-DIST not found!\n"
      exit 1
    fi
    printf "\n"

    # Get last commit to SEISREC-DEV
    if [ "$sta_type" == "DEV" ]; then
      if [ -d "$workdir/SEISREC-DEV" ]; then
        if ! cd "$workdir/SEISREC-DEV"; then
          printf "Error cd'ing into %s\n" "$workdir/SEISREC-DEV"
          exit 1
        else
          if git log | head -5 >/dev/null 2>&1; then
            printf "\nSEISREC-DEV last commit to branch %s:\n\n" "$(git branch | grep "\*.*" | sed -e "s/* //")"
            printf "%s\n\n" "$(git log | head -5)"
            if git describe --tags >/dev/null 2>&1; then
              version=$(git describe --tags)
            fi
            if [ -n "$version" ]; then
              printf "\nSoftware Version: %s\n" "$version"
            fi
          else
            printf "Error getting git logs!\n"
          fi
        fi
      else
        printf "SEISREC-DEV not found!\n"
        exit 1
      fi
    fi
    printf "\n"

    # Select update by version or simple git pull
    PS3='Selection: '
    if [ "$sta_type" == "DEV" ]; then
      options=("DIST software version" "DEV software version" "Manual Update" "Back")
    else
      options=("DIST software version" "Manual Update" "Back")
    fi
    select opt in "${options[@]}"; do
      case $opt in
      "Manual Update")
      # Manual update pulls most recent commit from remote
      print_title "Manual Update"
        while [ -z "$continue" ]; do
          if ! read -r -p "Update station? [Yes/No] " continue; then
            printf "Error reading STDIN! Aborting...\n"
            exit 1
          elif [[ "$continue" =~ [yY].* ]]; then
            if [ -d "$workdir" ]; then
              if ! cd "$workdir"; then
                printf "Error cd'ing into %s\n" "$workdir"
                exit 1
              fi

              printf "Pulling changes from SEISREC-DIST remote...\n\n"
              git pull

              if [ "$sta_type" == "DEV" ]; then
                if [ -d "$workdir/SEISREC-DEV" ]; then
                  if ! cd "$workdir/SEISREC-DEV"; then
                    printf "Error cd'ing into %s/SEISREC-DEV\n" "$workdir"
                    exit 1
                  fi

                  printf "\nPulling changes from SEISREC-DEV remote...\n\n"
                  git pull
                else
                  printf "%s/SEISREC-DEV not found!\n" "$workdir"
                fi
              fi
            else
              printf "%s/SEISREC-DEV not found!\n" "$workdir"
            fi
            break
          elif [[ "$continue" =~ [nN].* ]]; then
            break
          else
            continue=""
          fi
        done
        any_key
        break
        ;;

      "DIST software version")
        # Print current DIST version
        while [ -z "$continue" ]; do
          print_title "Update DIST softare version"
          if ! cd "$workdir"; then
            printf "Error cd into %s!\n" "$workdir"
          fi
          if git describe --tags >/dev/null 2>&1; then
            version=$(git describe --tags)
            printf "Current DIST software version: %s\n" "$version"
          else
            printf "Current commit has no tags.\n"
          fi

          printf "\n"
          if ! read -r -p "Change DIST software version? [Yes/No] " continue; then
            printf "Error reading STDIN! Aborting...\n"
            exit 1
          elif [[ "$continue" =~ [yY].* ]]; then
            # Get and print list of tags to checkout
            versionlist=$(git tag -l)
            if [ -z "$versionlist" ]; then
              printf "No versions found!\n"
              any_key
              break
            fi

            PS3='Select Version: '
            options=()
            for f in $(printf "%s" "$versionlist" | sed -e 's/$version\n//'); do
              options+=( "$f" )
            done
            options+=( "Exit" )
            select opt in "${options[@]}"; do
              if [ -n "$debug" ]; then
                printf "opt = %s\n" "$opt"
              fi

              # Try checking out tag
              if [ "$opt" == "Exit" ]; then
                  break
              elif ! "git checkout tags/$opt"; then
                printf "Error updating software!\n"
                continue=''
                any_key
                break
              fi
            done
          elif [[ "$continue" =~ [nN].* ]]; then
            break
          else
            continue=""
          fi
        done
        break
        ;;

      "DEV software version")
        # Print current DEV version
        while [ -z "$continue" ]; do
          print_title "Update DIST softare version"
          if [ "$sta_type" != "DEV" ]; then
            printf "Error in sta_type!\n"
            exit 1
          fi

          if ! cd "$workdir/SEISREC-DEV"; then
            printf "Error cd into %s!\n" "$workdir"
          fi
          if git describe --tags >/dev/null 2>&1; then
            version=$(git describe --tags)
          printf "Current DEV software version: %s\n" "$version"
          else
            printf "Current commit has no tags.\n"
          fi
          printf "\n"

          if ! read -r -p "Change DEV software version? [Yes/No] " continue; then
            printf "Error reading STDIN! Aborting...\n"
            exit 1
          elif [[ "$continue" =~ [yY].* ]]; then
            # Get and print list of tags to checkout
            versionlist=$(git tag -l)
            if [ -z "$versionlist" ]; then
              printf "No versions found!\n"
              any_key
              break
            fi

            PS3='Select DEV Version: '
            options=()
            for f in $(printf "%s" "$versionlist" | sed -e 's/$version\n//'); do
              options+=( "$f" )
            done
            select opt in "${options[@]}"; do
              if [ -n "$debug" ]; then
                printf "opt = %s" "$opt"
              fi

              # Try checking out tag
              if [ "$opt" == "Exit" ]; then
                  break
              elif ! "git checkout tags/$opt"; then
                printf "Error updating software!\n"
                continue=''
                any_key
                break
              fi
            done
            continue=""
            break
          elif [[ "$continue" =~ [nN].* ]]; then
            break
          else
            continue=""
          fi
          break
        done
        break
        ;;

      "Back")
        answered="yes"
        break
        ;;
      esac
    done
  done

  if [ -d "$currdir" ]; then
    if ! cd "$currdir"; then
      printf "Error cd'ing into %s\n" "$currdir"
      exit 1
    fi
  else
    printf "%s not found!\n" "$currdir"
  fi
}
##################################################################################################################################
# MANAGE SERVICES
# ################################################################################################################################
function manage_services() {
  local PS3
  local options
  local opt
  local choice
  local REPLY
  local menu_title
  local answered

  while [ -z "$answered" ]; do
    choice=""
    print_title "MANAGE SERVICES - SEISREC_config.sh"

    # Get enabled services
    enabled_services=$(systemctl list-unit-files)

    # Get SEISREC services
    services=$(ls "$repodir/SEISREC-DIST/services")
    printf "\nService status:\n"
    for s in $services; do
      if [ -n "$debug" ]; then
        printf "s = %s\n" "$s"
      fi
      servcheck=$(printf "%s" "$enabled_services" | grep "$s")
      if [ -n "$debug" ]; then
        printf "servcheck = %s\n" "$servcheck"
      fi
      if [ -n "$servcheck" ]; then
        printf "%s\n" "$servcheck"
      fi
    done

    # Assemble selected services file if it doesn't exist
    if [ ! -f "$workdir/selected_services_file.tmp" ]; then
      printf "%s" "$(ls "$repodir/SEISREC-DIST/services" | grep ".*.service")" >>"$workdir/selected_services_file.tmp"
    fi

    # Get list from temp file for display
    local list
    if [ -f "$workdir/selected_services_file.tmp" ]; then
      list=$(cat "$workdir/selected_services_file.tmp")
      printf "\nSelected services for management: "
      for l in $list; do
        printf "%s " "$l"
      done
      printf "\n"
    fi

    local opts=()
    opts+=("-f" "$workdir/selected_services_file.tmp")
    if [ -n "$debug" ]; then
      opts+=(-d)
    fi

    # Select action for services and run install_services.sh
    PS3='Selection: '
    options=("Start" "Stop" "Disable" "Clean" "Install" "Select Services" "Back")
    select opt in "${options[@]}"; do
      case $opt in
      "Start")
        choice="Start"
        opts+=("$choice")
        if [ -n "$debug" ]; then
          printf "opts = "
          printf "%s " "${opts[@]}"
          printf "\n"
        fi
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"
        any_key
        break
        ;;
      "Stop")
        choice="Stop"
        opts+=("$choice")
        if [ -n "$debug" ]; then
          printf "opts = "
          printf "%s " "${opts[@]}"
          printf "\n"
        fi
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"
        any_key
        break
        ;;
      "Disable")
        choice="Disable"
        opts+=("$choice")
        if [ -n "$debug" ]; then
          printf "opts = "
          printf "%s " "${opts[@]}"
          printf "\n"
        fi
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"
        any_key
        break
        ;;
      "Clean")
        choice="Clean"
        opts+=("$choice")
        if [ -n "$debug" ]; then
          printf "opts = "
          printf "%s " "${opts[@]}"
          printf "\n"
        fi
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"
        any_key
        break
        ;;
      "Install")
        choice="Install"
        opts+=("$choice")
        if [ -n "$debug" ]; then
          printf "opts = "
          printf "%s " "${opts[@]}"
          printf "\n"
        fi
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"
        any_key
        break
        ;;
      "Select Services")
        printf "%s" "$(ls $repodir/SEISREC-DIST/services | grep ".*.service")" >>"$workdir/available_services.tmp"
        select_several_menu "SELECT SERVICES - SEISREC-config.sh" "$workdir/available_services.tmp" "$workdir/selected_services_file.tmp"
        break
        ;;
      "Back")
        answered="yes"
        printf "Cleaning up & exiting...\n"
        clean_up "$workdir/available_services.tmp"
        clean_up "$workdir/selected_services_file.tmp"
        if [ -n "$debug" ]; then
          printf "Bye bye!\n"
        fi
        break
        ;;
      *)
        printf "invalid option %s\n" "$REPLY"
        break
        ;;
      esac
    done
  done
}

##################################################################################################################################
# GET SOFTWARE INFO FUNCTION
# ################################################################################################################################
function get_software_info() {
  print_title "DETAILED SOFTWARE INFO - SEISREC-config.sh"

  if [ -z "$sta_type" ]; then
    printf "Station Type not defined!\n"
    exit 1
  fi

  # Get current working directory for return point
  local currdir=$(pwd)

  if [ -d "$workdir" ]; then
    if ! cd "$workdir"; then
      printf "Error cd'ing into %s\n" "$workdir"
      exit 1
    else
      # Get last commit info
      if git log | head -5 >/dev/null 2>&1; then
        printf "SEISREC-DIST last commit to branch %s:\n\n" "$(git branch | grep "\*.*" | sed -e "s/* //")"
        printf "%s" "$(git log | head -5)"
      else
        printf "Error getting git logs!\n"
      fi
    fi
  else
    printf "SEISREC-DIST not found!\n"
    exit 1
  fi
  printf "\n"
  if [ "$sta_type" == "DEV" ]; then
    if [ -d "$workdir/SEISREC-DEV" ]; then
      if ! cd "$workdir/SEISREC-DEV"; then
        printf "Error cd'ing into %s\n" "$workdir/SEISREC-DEV"
        exit 1
      else
        # Get last commit info
        if git log | head -5 >/dev/null 2>&1; then
          printf "SEISREC-DEV last commit to branch %s:\n\n" "$(git branch | grep "\*.*" | sed -e "s/* //")"
          printf "%s\n\n" "$(git log | head -5)"
        else
          printf "Error getting git logs!\n"
        fi
      fi
    else
      printf "SEISREC-DEV not found!\n"
      exit 1
    fi
  fi

  # Display Info

  print_exec_versions

  printf "Linux Software Versions:\n\n"

  printf "Python Version: %s" "$(python3 --version | sed -e "s/Python //")"

  printf "\n"
  printf "Redis Server Version: %s\n" "$(redis-server -v | grep -o "v=.* sha" | sed -e "s/v=//" | sed -e "s/sha//")"
  printf "Redis Client Version: %s\n" "$(redis-cli -v | grep -o " .*$" | sed -e "s/ //")"

  printf "\n"
  printf "MRAA C lib Version: %s\n" "$(sudo ldconfig -v 2>&1 | grep mraa | tail -1 | grep -m2 -o "> libmraa.so.*.$" | sed -e "s/> libmraa.so.//")"
  printf "hiredis C lib Version: %s\n" "$(sudo ldconfig -v 2>&1 | grep hiredis | tail -1 | grep -m2 -o "> libhiredis.so.*.$" | sed -e "s/> libhiredis.so.//")"

  printf "\n"

  if [ "$sta_type" == "DEV" ]; then
    printf "\n"
    printf "Hiredis Python %s\n" "$(pip3 show hiredis | grep Version)"
    printf "Pyinstaller %s\n" "$(pip3 show pyinstaller | grep Version)"
  fi

  printf "\n"
  printf "NTP Version: %s\n" "$(dpkg -l | grep "hi  ntp" | grep -o "1:....." | sed -e "s/1://")"
  printf "GPSD Version: %s\n" "$(gpsd -V | grep -o "revision.*)" | sed -e "s/revision //" | sed -e "s/)//")"

  # Return to working directory
  if [ -d "$currdir" ]; then
    if ! cd "$currdir"; then
      printf "Error cd'ing into %s\n" "$currdir"
      exit 1
    fi
  else
    printf "%s not found!\n" "$currdir"
  fi

  any_key
}

##################################################################################################################################
# STATION SETUP FUNCTION
# ################################################################################################################################
function setup_station() {
  local cfgeverywhere=""

  print_title "STATION SETUP - SEISREC-config.sh"

  printf "Preparing setup...\n"
  printf "Checking for updates...\n"
  # Update Station software
  update_station_software

  printf "Setting up station parameters...\n"
  # Set up station parameters for operation
  configure_station

  # Install Services after configuring parameters
  printf "Installing services...\n"
  local opts=("INSTALL")
  if [ -n "$debug" ]; then
    opts+=(-d)
  fi
  if ! "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"; then
    printf "Error installing services! Please fix problems before retrying!\n"
    exit 1
  fi

  # Prompt for installing SEISREC-config utility
  if ! read -r -p "Install SEISREC-config? [Yes/No]" continue; then
    printf "Error reading STDIN! Aborting...\n"
    exit 1
  elif [[ "$continue" =~ [yY].* ]]; then
    cfgeverywhere="yes"
  elif [[ "$continue" =~ [nN].* ]]; then
    cfgeverywhere=""
  fi

  if [ -n "$cfgeverywhere" ]; then
    # if symlink to SEISREC-config doesn't exist, create it
    if [ ! -h "$repodir/SEISREC-DIST/SEISREC-config" ]; then
      printf "Creating symlinks to SEISREC-config...\n"
      ln -s "$repodir/SEISREC-DIST/scripts/SEISREC-config.sh" "$repodir/SEISREC-DIST/SEISREC-config"
    fi

    if ! cp "$HOME/.bashrc" "$HOME/.bashrc.bak"; then
      printf "Error backing up .bashrc!\n"
    fi

    # Check if ~/SEISREC is in PATH, if not, add it to PATH
    inBashrc=$(cat "$HOME/.bashrc" | grep 'SEISREC-DIST')
    inPath=$(printf "%s" "$PATH" | grep 'SEISREC-DIST')
    if [ -z "$inBashrc" ]; then
      if [ -z "$inPath" ]; then
        # Add it permanently to path
        printf "Adding ./SEISREC-DIST to PATH...\n"
        printf "inPath=\"\$(printf \"\$PATH\" | grep \"%s/SEISREC-DIST\")\"\n" "$repodir" >>~/.bashrc
        printf 'if [ -z "$inPath" ]\n' >>~/.bashrc
        printf 'then\n' >>~/.bashrc
        printf '  export PATH="%s/SEISREC-DIST:$PATH"\n' "$repodir" >>~/.bashrc
        printf 'fi\n' >>~/.bashrc
        printf "\n\nalias servcheck='sudo systemctl status neom8.service ; sudo systemctl status adxl355.service ; sudo systemctl status dyndns-manager.service ; sudo systemctl status db2file.service ; sudo systemctl status ds3231sn.service ; sudo systemctl status redis_6379_2.service ; sudo systemctl status ntp2.service'" >>~/.bashrc
      fi
    fi
  fi
  any_key
}

##################################################################################################################################
# DIST 2 DEV
# ################################################################################################################################
function dist2dev() {
  print_title "$sta_type TO $other_sta_type - SEISREC_config"
  local opts=()
  if [ -n "$debug" ]; then
    opts+=(-d)
  fi
  opts+=("$other_sta_type")

  # Automatically switch software version
  "$repodir/SEISREC-DIST/scripts/dist2dev.sh" "${opts[@]}"
  any_key
}

##################################################################################################################################
# SEISREC_build
# ################################################################################################################################
function SEISREC-build() {
  local opts=()
  if [ -n "$debug" ]; then
    opts+=(-d)
  fi
  # Build software using SEISREC-BUILD
  "$repodir/SEISREC-DIST/SEISREC-DEV/scripts/SEISREC_build.sh" "${opts[@]}"
}

##################################################################################################################################
# MANAGE NTP
# ################################################################################################################################
function manage_ntp() {
  local PS3
  local options
  local opt
  local choice
  local REPLY
  local answered

  while [ -z "$answered" ]; do
    choice=""
    print_title "MANAGE NTP - SEISREC_config"

    local opts=()
    if [ -n "$debug" ]; then
      opts+=(-d)
    fi
    PS3='Selection: '
    options=("Edit NTP .conf File" "Load .conf file from distro" "View ntp.conf" "Back")
    select opt in "${options[@]}"; do
      case $opt in
      "Edit NTP .conf File")
        if [ -f "/etc/ntp.conf" ]; then
          if ! sudo nano /etc/ntp.conf; then
            printf "Error editing /etc/ntp.conf! \n"
          fi
        else
          printf "Couldn't find /etc/ntp.conf!\n"
        fi
        break
        ;;
      "Load .conf file from distro")
        local ans
        while [ -z "$continue" ]; do
          if ! read -r -p "This will completely overwrite the existing system ntp.conf. Are you sure? [Y/N]" continue; then
            printf "Error reading STDIN! Aborting...\n"
            exit 1
          elif [[ "$continue" =~ [yY].* ]]; then
            if [ -f "/etc/ntp.conf" ]; then
              if ! sudo rm "/etc/ntp.conf"; then
                printf "Error removing /etc/ntp.conf!"
              fi
            fi
            if ! cp "$workdir/sysfiles/ntp.conf" "/etc/ntp.conf"; then
              printf "Error copying /etc/ntp.conf! \n"
              any_key
            fi
            break
          elif [[ "$continue" =~ [sS].* ]]; then
            break
          else
            continue=""
          fi
        done
        break
        ;;
      "View ntp.conf")
        if [ -f "/etc/ntp.conf" ]; then
          if ! sudo cat "/etc/ntp.conf"; then
            printf "Error viewing /etc/ntp.conf!"
          fi
        else
          printf "Couldn't find /etc/ntp.conf!\n"
        fi
        any_key
        break
        ;;
      "Back")
        answered="yes"
        break
        ;;
      *)
        printf "invalid option %s\n" "$REPLY"
        break
        ;;
      esac
    done
  done
  #under_construction
}

##################################################################################################################################
# MANAGE NETWORKS
# ################################################################################################################################
function manage_networks() {
  local PS3
  local options
  local opt
  local choice
  local REPLY
  local answered

  while [ -z "$answered" ]; do
    choice=""
    print_title "MANAGE NETWORKS - SEISREC_config"

    local opts=()
    if [ -n "$debug" ]; then
      opts+=(-d)
    fi
    PS3='Selection: '
    options=("Configure Interface IP Address" "Configure Network Priority" "Back")
    select opt in "${options[@]}"; do
      case $opt in
      "Configure Interface IP Address")
        under_construction
        # TODO: Write IP config function
        any_key
        break
        ;;
      "Configure Network Priority")
        if [ -f "$workdir/sysfiles/dhcpcd.conf" ]; then
          if ! sudo nano "$workdir/sysfiles/dhcpcd.conf"; then
            printf "Error editing %s/sysfiles/dhcpcd.conf! \n" "$workdir"
            any_key
          fi
        else
          printf "Couldn't find %s/sysfiles/dhcpcd.conf!\n" "$workdir"
          any_key
        fi
        break
        ;;
      "Back")
        answered="yes"
        break
        ;;
      *)
        printf "invalid option %s\n" "$REPLY"
        break
        ;;
      esac
    done
  done
}

##################################################################################################################################
# PERFORMANCE REPORT
# ################################################################################################################################
function performance_report() {
  print_title "PERFORMANCE REPORT - SEISREC_config"
  # TODO: write performance tests
  under_construction
  any_key
}
##################################################################################################################################
# UNINSTALL SEISREC
# ################################################################################################################################
function uninstall_seisrec() {
  print_title "UNINSTALL SEISREC - SEISREC_config"
  local currdir=$(pwd)

  if [ -n "$(pwd | grep "SEISREC-DIST")" ]; then
    if [ -n "$debug" ]; then
      printf "Current working directory is inside SESIREC-DIST"
    fi
    cd "$HOME"
  fi

  local opts=()
  if [ -n "$debug" ]; then
    opts+=(-d)
  fi
  while [ -z "$continue" ]; do
    if ! read -r -p "This will uninstall all SEISREC software from device. Continue? [Yes/No] " continue; then
      printf "Error reading STDIN! Aborting...\n"
      exit 1
    elif [[ "$continue" =~ [yY].* ]]; then
      choice="disable"
      opts+=(-n "$choice")
      if ! "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"; then
        printf "Error disabling services!\n"
      fi

      if ! rm "$HOME/.bashrc"; then
        printf "Error removing .bashrc!\n"
      fi

      if ! mv "$HOME/.bashrc.bak" "$HOME/.bashrc"; then
        printf "Error restoring .bashrc!\n"
      fi

      export PATH=$(printf "%s" "$PATH" | sed -e "s|$repodir/SEISREC-DIST:||")

      if ! sudo rm -r "$repodir/SEISREC-DIST/"; then
        printf "Error removing SEISREC-DIST repository!\n"
        exit 1
      fi

      printf "To reinstall software, clone from https://github.com/alexbecerra/SEISREC-DIST.git\n"
      any_key
      exit 0

    elif [[ "$continue" =~ [nN].* ]]; then
      break
    else
      continue=""
    fi
  done
  any_key
}

##################################################################################################################################
# UTILITIES
# ################################################################################################################################
function check_sta_type() {

  if [ -d "$repodir/SEISREC-DIST/SEISREC-DEV/" ]; then
    currdir=$(pwd)
    if ! cd "$repodir/SEISREC-DIST/SEISREC-DEV/"; then
      printf "Error cd'ing into SEISREC-DEV!\n"
    fi
    reponame=$(basename $(git rev-parse --show-toplevel))
    if [ "$reponame" == "SEISREC-DEV" ]; then
      sta_type="DEV"
      other_sta_type="DIST"
    else
      printf "SEISREC-DEV directory present, but has wrong repository!\n"
    fi
  else
    sta_type="DIST"
    other_sta_type="DEV"
  fi
}
#*********************************************************************************************************************************
# MAIN BODY
#*********************************************************************************************************************************

print_title
print_banner
printf "\n"
any_key

if [ -n "$debug" ]; then
  printf "repodir = %s\n" "$repodir"
fi

check_sta_type
#=================================================================================================================================
# CLEAN UP FUNCTION
#=================================================================================================================================

while [ -z "$done" ]; do
  print_title "MAIN MENU - SEISREC_config"
  PS3='Selection: '
  options=("Software Setup & Update" "Station Info & Tests" "Advanced Options" "Help" "Quit")
  select opt in "${options[@]}"; do
    case $opt in
    "Advanced Options")
      choice="Advanced Options"
      break
      ;;
    "Station Info & Tests")
      choice="Station Info & Tests"
      break
      ;;
    "Software Setup & Update")
      choice="Software Setup & Update"
      break
      ;;
    "Help")
      print_help
      break
      ;;
    "Quit")
      printf "Good bye!\n"
      exit 0
      ;;
    *)
      printf "invalid option %s\n" "$REPLY"
      break
      ;;
    esac
  done

  if [ -n "$debug" ]; then
    printf "choice = %s\n" "$choice"
  fi

  #=================================================================================================================================
  # CLEAN UP FUNCTION
  #=================================================================================================================================
  case $choice in
  #-------------------------------------------------------------------------------------------------------------------------------
  # Advanced Options
  #-------------------------------------------------------------------------------------------------------------------------------
  "Advanced Options")
    done=""
    if [ ! -f "$repodir/SEISREC-DIST/parameter" ]; then
      printf "No parameter file found! Please run station setup first!\n"
      any_key
    else
      while [ -z "$done" ]; do
        check_sta_type

        print_title "CONFIGURE STATION SOFTWARE - SEISREC_config.sh"
        if [ "$sta_type" == "DEV" ]; then
          options=("Configure Station Parameters" "Manage Unit Services" "Manage Networks" "Manage NTP" "Convert to $other_sta_type" "Build Station Software" "Back")
        else
          options=("Configure Station Parameters" "Manage Unit Services" "Manage Networks" "Manage NTP" "Convert to $other_sta_type" "Back")
        fi
        select opt in "${options[@]}"; do
          case $opt in
          "Configure Station Parameters")
            configure_station
            break
            ;;
          "Manage Unit Services")
            manage_services
            break
            ;;
          "Manage Networks")
            manage_networks
            break
            ;;
          "Convert to $other_sta_type")
            dist2dev
            break
            ;;
          "Build Station Software")
            SEISREC-build
            break
            ;;
          "Manage NTP")
            manage_ntp
            break
            ;;
          "Back")
            done="yes"
            break
            ;;
          *)
            printf "invalid option %s\n" "$REPLY"
            break
            ;;
          esac
        done
      done
      done=""
    fi
    ;;
    #-------------------------------------------------------------------------------------------------------------------------------
    # Station Info & Tests
    #-------------------------------------------------------------------------------------------------------------------------------
  "Station Info & Tests")
    done=""
    while [ -z "$done" ]; do
      print_title "STATION INFO - SEISREC_config.sh"
      options=("Run Station Tests" "Detailed Software Info" "Performance Reports" "Back")
      select opt in "${options[@]}"; do
        case $opt in
        "Run Station Tests")
          "$repodir/SEISREC-DIST/scripts/SEISREC-TEST.sh"
          any_key
          break
          ;;
        "Detailed Software Info")
          get_software_info
          break
          ;;
        "Performance Reports")
          performance_report
          break
          ;;
        "Back")
          done="yes"
          break
          ;;
        *)
          printf "invalid option %s\n" "$REPLY"
          break
          ;;
        esac
      done
    done
    done=""
    ;;
    #-------------------------------------------------------------------------------------------------------------------------------
    # Software Setup & Update
    #-------------------------------------------------------------------------------------------------------------------------------
  "Software Setup & Update")
    done=""
    while [ -z "$done" ]; do
      continue=""
      print_title "STATION SOFTWARE & UPDATE - SEISREC_config.sh"
      if [ ! -f "$repodir/SEISREC-DIST/parameter" ]; then
        printf "Station is not set up.\n"
        while [ -z "$continue" ]; do
          if ! read -r -p "Proceed with station setup? [Yes/Skip] " continue; then
            printf "Error reading STDIN! Aborting...\n"
            exit 1
          elif [[ "$continue" =~ [yY].* ]]; then
            setup_station
          elif [[ "$continue" =~ [sS].* ]]; then
            break
          else
            continue=""
          fi
        done
      fi
      print_title "STATION SOFTWARE & UPDATE - SEISREC_config.sh"

      options=("SEISREC version & update" "Station Setup" "Uninstall" "Back")
      select opt in "${options[@]}"; do
        case $opt in
        "SEISREC version & update")
          update_station_software
          break
          ;;
        "Station Setup")
          if [ -f "$repodir/SEISREC-DIST/parameter" ]; then
            printf "Station appears to be already set up.\n"
            if ! read -r -p "Configure station from scratch? [Yes/No] " continue; then
              printf "Error reading STDIN! Aborting...\n"
              exit 1
            elif [[ "$continue" =~ [yY].* ]]; then
              if ! read -r -p "This will overwrite current station configuration! Are you sure? [Yes/No] " continue; then
                printf "Error reading STDIN! Aborting...\n"
                exit 1
              elif [[ "$continue" =~ [yY].* ]]; then
                clean_up "$repodir/SEISREC-DIST/parameter"
              elif [[ "$continue" =~ [nN].* ]]; then
                break
              fi
            elif [[ "$continue" =~ [nN].* ]]; then
              break
            fi
          fi
          setup_station
          break
          ;;
        "Uninstall")
          uninstall_seisrec
          break
          ;;
        "Back")
          done="yes"
          break
          ;;
        *)
          printf "invalid option %s\n" "$REPLY"
          break
          ;;
        esac
      done
    done
    done=""
    ;;
  esac
done
printf "Good bye!\n"
exit 0
