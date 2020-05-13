#!/bin/bash

debug=''
choice=""
done=""
cfgeverywhere=""
sta_type="DIST"
other_sta_type="DEV"

##################################################################################################################################
# GET  WORKING DIRECTORY
# ################################################################################################################################
if [ -z "$repodir" ]; then
  repodir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
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
    opts+=(-debug)
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
  print_title "SYSTEM UPDATE- SEISREC-config.sh"
  # TODO: Complete section
  local currdir=$(pwd)

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

  if [ -d "$currdir" ]; then
    if ! cd "$currdir"; then
      printf "Error cd'ing into %s\n" "$currdir"
      exit 1
    fi
  else
    printf "%s not found!\n" "$currdir"
  fi
  under_construction
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

    local opts=()
    if [ -n "$debug" ]; then
      opts+=(-d)
    fi
    opts+=(-f "$workdir/selected_services_file.tmp")
    PS3='Selection: '
    options=("Start" "Stop" "Disable" "Clean" "Install" "Select Services" "Back")
    select opt in "${options[@]}"; do
      case $opt in
      "Start")
        choice="Start"
        opts+=("$choice")
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"
        any_key
        break
        ;;
      "Stop")
        choice="Stop"
        opts+=("$choice")
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"
        any_key
        break
        ;;
      "Disable")
        choice="Disable"
        opts+=("$choice")
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"
        any_key
        break
        ;;
      "Clean")
        choice="Clean"
        opts+=("$choice")
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"
        any_key
        break
        ;;
      "Install")
        choice="Install"
        opts+=("$choice")
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
# CLEAN UP FUNCTION
# ################################################################################################################################
function get_software_info() {
  print_title "DETAILED SOFTWARE INFO - SEISREC-config.sh"

  if [ -z "$sta_type" ]; then
    printf "Station Type not defined!\n"
    exit 1
  fi

  local currdir=$(pwd)

  if [ -d "$workdir" ]; then
    if ! cd "$workdir"; then
      printf "Error cd'ing into %s\n" "$workdir"
      exit 1
    else
      if git log | head -5 >/dev/null 2>&1; then
        printf "SEISREC-DIST last commit:\n\n"
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
        if git log | head -5 >/dev/null 2>&1; then
          printf "SEISREC-DEV last commit:\n\n"
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

  local all_folders=$(ls "$workdir")
  for d in $all_folders; do
    if [ -d "$workdir/$d" ]; then
      local files=$(ls "$workdir/$d")
      for f in $files; do
        local is_exec=$(printf "%s" "$f" | grep "$f")
        if [ -n "$is_exec" ]; then
        local tmpversion=$(strings "$workdir/$d/$f" | grep "Version: .*UTC")
        if [ -n "$tmpversion" ]; then
          printf "%s: \n  %s\n\n" "$f" "$tmpversion"
        fi
        fi
      done
    fi
  done

  if [ -d "$currdir" ]; then
    if ! cd "$currdir"; then
      printf "Error cd'ing into %s\n" "$currdir"
      exit 1
    fi
  else
    printf "%s not found!\n" "$currdir"
  fi
  # TODO: Add executable info display strings TEST_ACC355 | grep "Version: .*UTC"
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
  local opts=("INSTALL")
  if [ -n "$debug" ]; then
    opts+=(-d)
  fi
  if ! "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"; then
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
        printf "inPath=$(printf \"$PATH\" | grep "%s/SEISREC-DIST")\n" "$repodir" >>~/.bashrc
        printf 'if [ -z "$inPath" ]\n' >>~/.bashrc
        printf 'then\n' >>~/.bashrc
        printf '  export PATH="%s/SEISREC-DIST:$PATH"\n' "$repodir" >>~/.bashrc
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
    opts+=(-d)
  fi
  opts+=("$other_sta_type")
  "$repodir/SEISREC-DIST/scripts/dist2dev.sh" "${opts[@]}"
}

function SEISREC-build() {
  local opts=()
  if [ -n "$debug" ]; then
    opts+=(-d)
  fi
  "$repodir/SEISREC-DIST/SEISREC-DEV/scripts/SEISREC_build.sh" "${opts[@]}"
}

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
  # CLEAN UP FUNCTION
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
          options=("Configure Station Parameters" "Manage Unit Services" "Manage Networks" "Convert to $other_sta_type" "Build Station Software" "Back")
        else
          options=("Configure Station Parameters" "Manage Unit Services" "Manage Networks" "Convert to $other_sta_type" "Back")
        fi
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
          "Build Station Software")
            SEISREC-build
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
