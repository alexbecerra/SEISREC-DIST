#!/bin/bash

debug=''
choice=""
done=""
cfgeverywhere=""
sta_type="DIST"
other_sta_type="DEV"

##################################################################################################################################
# CLEAN UP FUNCTION
# ################################################################################################################################

source "$workdir/scripts/script_utils.sh"

##################################################################################################################################
# PRINT HELP SECTION
# ################################################################################################################################
function print_help() {
  print_title "AYUDA - SEISREC-config.sh"
  under_construction
  # TODO: Write Help Section
}

##################################################################################################################################
# CONFIGURE STATION PARAMS
# ################################################################################################################################
function configure_station() {
  local opts=()
  opts+=(-pth "$repodir/SEISREC-DIST/")
  if [ -n "$debug" ]; then
    printf "opts = "
    for o in "${opts[@]}"; do
      printf "%s " "$o"
    done
    printf "\n"
  fi
  print_title "CONFIGURE STATION PARAMETERS - SEISREC-config.sh"
  "$repodir/SEISREC-DIST/util/util_paramedit" "${opts[@]}"
}

##################################################################################################################################
# UPDATE SYSTEM SOFTWARE
# ################################################################################################################################
function update_station_software() {
  # TODO: Complete section
  printf "BAJO CONSTRUCCIÓN!\n"
  printf "\n"
  printf "This function should update the SEISREC-DIST software!\n"
  printf "Maybe Check what versions are available and then select\n"
  printf "for download from repository\n"
  printf "\n"
  printf "\n"
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
    print_title "MANAGE SERVICES - SEISREC_config.sh"

    enabled_services=$(systemctl list-unit-files)
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

    if [ ! -f "$workdir/selected_services_file.tmp" ]; then
      printf "%s" "$(ls "$repodir/SEISREC-DIST/services" | grep ".*.service")" >>"$workdir/selected_services_file.tmp"
    fi

    local list
    if [ -f "$workdir/selected_services_file.tmp" ]; then
      list=$(cat "$workdir/selected_services_file.tmp")
      printf "\nSelected services for management: "
      for l in $list; do
        printf "%s " "$l"
      done
      printf "\n"
    fi
    PS3='Selection: '
    options=("Start" "Stop" "Disable" "Clean" "Install" "Select Services" "Back")
    select opt in "${options[@]}"; do
      case $opt in
      "Start")
        choice="Start"
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "$choice" "$workdir/selected_services_file.tmp"
        any_key
        break
        ;;
      "Stop")
        choice="Stop"
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "$choice" "$workdir/selected_services_file.tmp"
        any_key
        break
        ;;
      "Disable")
        choice="Disable"
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "$choice" "$workdir/selected_services_file.tmp"
        any_key
        break
        ;;
      "Clean")
        choice="Clean"
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "$choice" "$workdir/selected_services_file.tmp"
        any_key
        break
        ;;
      "Install")
        choice="Install"
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "$choice" "$workdir/selected_services_file.tmp"
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
# CLEAN UP FUNCTION
# ################################################################################################################################
function get_software_info() {
  print_title "DETAILED SOFTWARE INFO - SEISREC-config.sh"
  under_construction
  # TODO: Complete section
}

##################################################################################################################################
# STATION SETUP FUNCTION
# ################################################################################################################################
function setup_station() {
  print_title "STATION SETUP - SEISREC-config.sh"

  printf "Preparing setup...\n"

  printf "Checking for updates...\n"
  update_station_software

  printf "Setting up station parameters...\n"
  configure_station

  printf "Installing services...\n"
  if ! "$repodir/SEISREC-DIST/scripts/install_services.sh" "INSTALL"; then
    printf "Error installing services! Please fix problems before retrying!\n"
    exit 1
  fi

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
}

##################################################################################################################################
# CLEAN UP FUNCTION
# ################################################################################################################################
function dist2dev() {
  print_title "$sta_type TO $other_sta_type - SEISREC_config"
  local opts=()
  if [ -n "$debug" ]; then
    opts+=( "-d" )
  fi
  opts+=("$other_sta_type")
  "$repodir/SEISREC-DIST/scripts/dist2dev.sh" "${opts[@]}"
}

#*********************************************************************************************************************************
# MAIN BODY
#*********************************************************************************************************************************
if [ -z "$repodir" ]; then
  repodir="$HOME"
fi
workdir="$repodir/SEISREC-DIST"

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

print_title
print_banner
printf "\n"
any_key

if [ -n "$debug" ]; then
  printf "repodir = %s\n" "$repodir"
fi

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
  # CLEAN UP FUNCTION
  #-------------------------------------------------------------------------------------------------------------------------------
  "Advanced Options")
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
      sta_type="DEV"
      other_sta_type="DIST"
    fi
    done=""
    if [ ! -f "$repodir/SEISREC-DIST/parameter" ]; then
      printf "No parameter file found! Please run station setup first!\n"
      any_key
    else
      while [ -z "$done" ]; do
        print_title "CONFIGURE STATION SOFTWARE - SEISREC_config.sh"
        options=("Configure Station Parameters" "Manage Unit Services" "Manage Networks" "Convert to $other_sta_type" "Help" "Back")
        select opt in "${options[@]}"; do
          case $opt in
          "Configure Station Parameters")
            configure_station
            any_key
            break
            ;;
          "Manage Unit Services")
            manage_services
            any_key
            break
            ;;
          "Manage Networks")
            under_construction
            any_key
            break
            ;;
          "Convert to $other_sta_type")
            dist2dev
            any_key
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
    # CLEAN UP FUNCTION
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
          any_key
          break
          ;;
        "Performance Reports")
          under_construction
          any_key
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
    # CLEAN UP FUNCTION
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

      options=("SEISREC version & update" "Station Setup" "Back")
      select opt in "${options[@]}"; do
        case $opt in
        "SEISREC version & update")
          update_station_software
          any_key
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
          any_key
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
