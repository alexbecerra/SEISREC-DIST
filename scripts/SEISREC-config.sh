#!/bin/bash

debug=''
choice=""
done=""
cfgeverywhere=""

if [ -z "$repodir" ]; then
  repodir="$HOME"
fi

workdir="$repodir/SEISREC-DIST"

function print_banner() {
  printf "                                                                             \n"
  printf "███████╗███████╗██╗    ██╗       ██████╗███████╗███╗   ██╗\n"
  printf "██╔════╝██╔════╝██║    ██║      ██╔════╝██╔════╝████╗  ██║\n"
  printf "█████╗  █████╗  ██║ █╗ ██║█████╗██║     ███████╗██╔██╗ ██║\n"
  printf "██╔══╝  ██╔══╝  ██║███╗██║╚════╝██║     ╚════██║██║╚██╗██║\n"
  printf "███████╗███████╗╚███╔███╔╝      ╚██████╗███████║██║ ╚████║\n"
  printf "╚══════╝╚══════╝ ╚══╝╚══╝        ╚═════╝╚══════╝╚═╝  ╚═══╝\n"
}

function under_construction() {
  printf "\n"
  printf "  #######################################\n"
  printf "  #                                     #\n"
  printf "  #           UNDER CONSTRUCTION        #\n"
  printf "  #                                     #\n"
  printf "  #######################################\n"
  printf "\n"
}
##################################################################################################################################
# PRINT TITLE FUNCTION
# ################################################################################################################################
function print_title() {
  if ! cls; then
    if ! clear; then
      printf "D'OH"
    fi
  fi
  if [ -n "$1" ]; then
    while [ -n "$1" ]; do
      printf "%s" "$1"
      shift
    done
    printf "\n\n"
  fi
}

##################################################################################################################################
# CLEAN UP FUNCTION
# ################################################################################################################################
function clean_up() {
  local file
  file="$1"
  if [ -f "$file" ]; then
    if [ -n "$debug" ]; then
      printf "Removing %s\n" "$file"
    fi
    if ! rm "$file"; then
      printf "Error removing %s\n" "$file"
    fi
  fi
}
##################################################################################################################################
# CLEAN UP AFTER SIG-INT
# ################################################################################################################################
function any_key () {
  read -n 1 -r -s -p $'Press enter to continue...\n'
}

##################################################################################################################################
# CLEAN UP AFTER SIG-INT
# ################################################################################################################################

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
  if [ -n "$debug" ]; then
    printf "SIG-INT DETECTED!\n"
  fi
  local tempfiles
  tempfiles=$(ls "$workdir" | grep ".*.tmp")
  for t in $tempfiles; do
    clean_up "$t"
  done
  exit 1
}

##################################################################################################################################
# PRINT HELP SECTION
# ################################################################################################################################
function print_help() {
  print_title "HELP - SEISREC-config.sh"
  under_construction
}

##################################################################################################################################
# CONFIGURE STATION PARAMS
# ################################################################################################################################
function configure_station() {
  local opts
  opts=("-pth" "$repodir/SEISREC-DIST/")
  print_title "CONFIGURE STATION PARAMETERS - SEISREC-config.sh"
  "$repodir/SEISREC-DIST/util/util_paramedit" "${opts[@]}"
}

##################################################################################################################################
# UPDATE SYSTEM SOFTWARE
# ################################################################################################################################
function update_station_software() {
  printf "Under Construction!\n"
  printf "\n"
  printf "This function should update the SEISREC-DIST software!\n"
  printf "Maybe Check what versions are available and then select\n"
  printf "for download from repository\n"
  printf "\n"
  printf "\n"
}

##################################################################################################################################
# MENU FUNCTION
# ################################################################################################################################
function select_several_menu() {
  local menu_opts_file
  local menu_title
  local menu_selections
  local answered
  local optionnames
  local selected_names
  local selected_names_file

  menu_title="$1"
  menu_opts_file="$2"
  selected_names_file="$3"

  clean_up "$selected_names_file"

  optionnames=()
  if [ -f "$menu_opts_file" ]; then
    for n in $(cat "$menu_opts_file"); do
      optionnames+=("$n")
    done
  else
    printf "Menu options file not found!\n"
    exit 1
  fi

  while [ -z "$answered" ]; do
    print_title "$menu_title"
    printf "\n"
    indx=1
    for n in "${optionnames[@]}"; do
      printf " [%i]\t%s\n" "${indx}" "$n"
      indx=$((indx + 1))
    done
    printf " [0]\tSelect All \n"

    local ans

    read -r -p "Select Options: " ans
    for m in $ans; do
      if [[ "$m" =~ ^[0-9]$ ]]; then
        if [ -n "$debug" ]; then
          printf "%s input accepted\n" "$m"
        fi
        menu_selections+=("$((m - 1))")
      else
        if [ -n "$debug" ]; then
          printf "%s input rejected\n" "$m"
        fi
      fi
    done

    for n in "${menu_selections[@]}"; do
      if [ "$n" -eq -1 ]; then
        menu_selections=()
        indx=1
        for s in "${optionnames[@]}"; do
          menu_selections+=("$((indx - 1))")
          indx=$((indx + 1))
        done
        break
      fi
    done

    selected_names=()
    printf "\nOption Selected: "
    for n in "${menu_selections[@]}"; do
      selected_names+=("$n")
      printf "%s " "${optionnames[$((n))]}"
    done

    #---------------------------------------------------------------
    # CONFIG CONFIRMATION
    #---------------------------------------------------------------
    printf "\n[C]ontinue [R]eselect [A]bort ? "
    if ! read -r continue; then
      printf "Error reading STDIN! Aborting...\n"
      exit 1
    elif [[ "$continue" =~ [cC].* ]]; then
      answered="yes"
      if [ ! -f "$selected_names_file" ]; then
        touch "$selected_names_file"
      fi
      for n in "${selected_names[@]}"; do
        printf "%s\n" "${optionnames[$((n))]}" >>"$selected_names_file"
      done
      break
    elif [[ "$continue" =~ [rR].* ]]; then
      printf "Reselecting...\n"
    elif [[ "$continue" =~ [aA].* ]]; then
      printf "Cleaning up & exiting...\n"
      clean_up "$menu_opts_file"
      if [ -n "$debug" ]; then
        printf "Bye bye!\n"
      fi
    else
      printf "\n[C]ontinue [R]eselect [A]bort ? "
    fi
  done

  if [ -f "$menu_opts_file" ]; then
    if ! rm "$menu_opts_file"; then
      printf "Error removing aux files!\n"
    fi
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
      *) printf "invalid option %s\n" "$REPLY"
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
  if ! "$repodir/SEISREC-DIST/util/util_paramedit"; then
    printf "Error setting up station parameters! Please fix problems before retrying!\n"
    exit 1
  fi

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
  options=("Configure Station Software" "Station Info & Tests" "Software Setup & Update" "Help" "Quit")
  select opt in "${options[@]}"; do
    case $opt in
    "Configure Station Software")
      choice="Configure Station Software"
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
    *) printf "invalid option %s\n" "$REPLY"
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
  "Configure Station Software")
    done=""
    if [ ! -f "$repodir/SEISREC-DIST/parameter" ]; then
      printf "No parameter file found! Please run station setup first!\n"
      any_key
    else
      while [ -z "$done" ]; do
        print_title "CONFIGURE STATION SOFTWARE - SEISREC_config.sh"
        options=("Configure Station Parameters" "Manage Unit Services" "Help" "Back")
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
          "Back")
            done="yes"
            break
            ;;
          *) printf "invalid option %s\n" "$REPLY"
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
      options=("Run Station Tests" "Detailed Software Info" "Back")
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
        "Back")
          done="yes"
          break
          ;;
        *) printf "invalid option %s\n" "$REPLY"
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
        *) printf "invalid option %s\n" "$REPLY"
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
