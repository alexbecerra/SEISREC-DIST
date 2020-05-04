#!/bin/bash

debug=''
choice=""
done=""
cfgeverywhere=""

function print_help() {
  printf "\n"
  printf "\n"
  printf "\n"
  printf "\n"
  printf "\n"
  printf "\n"
  printf "\n"
}

clean_up () {
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

configure_station() {
  local opts
  opts=("-pth" "$repodir/SEISREC-DIST/")
  "$repodir/SEISREC-DIST/util/util_paramedit" "${opts[@]}"
}

update_station_software() {
  printf "Under Construction!\n"
  printf "\n"
  printf "This function should update the SEISREC-DIST software!\n"
  printf "Maybe Check what versions are available and then select\n"
  printf "for download from repository\n"
  printf "\n"
  printf "\n"
}

select_several_menu() {
  local menu_opts_file
  local menu_prompt
  local menu_selections
  local answered
  local optionnames
  local selected_names
  local selected_names_file

  menu_prompt="$1"
  menu_opts_file="$2"
  selected_names_file="$3"

  clean_up "$selected_names_file"

  optionnames=()
  if [ -f "$menu_opts_file" ]; then
    for n in $(cat "$menu_opts_file"); do
      optionnames+=( "$n" )
    done
  else
    printf "Menu options file not found!\n"
    exit 1
  fi

  while [ -z "$answered" ]; do
    printf "\n"
    indx=1
    for n in "${optionnames[@]}"; do
      printf " [%i]\t%s\n" "${indx}" "$n"
      indx=$((indx + 1))
    done
    printf " [0]\tSelect All \n"

    local ans

    read -r -p "$menu_prompt" ans
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
      selected_names+=( "$n" )
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
          printf "%s\n" "${optionnames[$((n))]}" >> "$selected_names_file"
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
          exit 0
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

manage_services() {
  local PS3
  local options
  local opt
  local choice
  local REPLY
  local menu_prompt
  local answered

  while [ -z "$answered" ]; do
  if [ ! -f "selected_services_file" ]; then
    printf "%s" "$(ls "$repodir/SEISREC-DIST/services" | grep ".*.service")" >> "selected_services_file"
  fi

  local list
  if [ -f "selected_services_file" ]; then
    list=$(cat "selected_services_file")
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
      "$repodir/SEISREC-DIST/scripts/install_services.sh" "$choice" "selected_services_file"
      break
      ;;
    "Stop")
      choice="Stop"
      "$repodir/SEISREC-DIST/scripts/install_services.sh" "$choice" "selected_services_file"
      break
      ;;
    "Disable")
      choice="Disable"
      "$repodir/SEISREC-DIST/scripts/install_services.sh" "$choice" "selected_services_file"
      break
      ;;
    "Clean")
      choice="Clean"
      "$repodir/SEISREC-DIST/scripts/install_services.sh" "$choice" "selected_services_file"
      break
      ;;
    "Install")
      choice="Install"
      "$repodir/SEISREC-DIST/scripts/install_services.sh" "$choice" "selected_services_file"
      break
      ;;
    "Select Services")
      printf "%s" "$(ls $repodir/SEISREC-DIST/services | grep ".*.service")" >> "available_services"
      select_several_menu "Select services:" "available_services" "selected_services_file"
      break
      ;;
    "Back")
    answered="yes"
      printf "Cleaning up & exiting...\n"
      clean_up "available_services"
      clean_up "selected_services_file"
      if [ -n "$debug" ]; then
        printf "Bye bye!\n"
      fi
      break
      ;;
    *) printf "invalid option %s\n" "$REPLY" ;;
    esac
  done
done
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

if [ -n "$debug" ]; then
  printf "repodir = %s\n" "$repodir"
fi

while [ -z "$done" ]; do
  printf "\n"
  PS3='Selection: '
  options=("Configure Station" "Station Setup" "Help" "Quit")
  select opt in "${options[@]}"; do
    case $opt in
    "Configure Station")
      choice="Configure Station"
      break
      ;;
    "Station Setup")
      choice="Station Setup"
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
    *) printf "invalid option %s\n" "$REPLY" ;;
    esac
  done

  if [ -n "$debug" ]; then
    printf "choice = %s\n" "$choice"
  fi

  case $choice in
  "Configure Station")
    if [ ! -f "$repodir/SEISREC-DIST/parameter" ]; then
      printf "No parameter file found! Please run station setup first!\n"
    else
      done=""
      while [ -z "$done" ]; do
        printf "\n"
        options=("Configure Station Parameters" "Manage Unit Services" "Run Station Tests" "Update Station Software" "Help" "Back")
        select opt in "${options[@]}"; do
          case $opt in
          "Configure Station Parameters")
            configure_station
            break
            ;;
          "Manage Unit Services")
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
            manage_services
            break
            ;;
          "Run Station Tests")
            "$repodir/SEISREC-DIST/scripts/SEISREC-TEST.sh"
            break
            ;;
          "Update Station Software")
            update_station_software
            break
            ;;
          "Back")
            done="yes"
            break
            ;;
          *) printf "invalid option %s\n" "$REPLY" ;;
          esac
        done
      done
      done=""
    fi
    ;;

  "Station Setup")
    if [ -f "$repodir/SEISREC-DIST/parameter" ]; then
      printf "Station appears to be already set up.\n"
      if ! read -r -p "Configure station from scratch? [Yes/No]" continue; then
        printf "Error reading STDIN! Aborting...\n"
        exit 1
      elif [[ "$continue" =~ [yY].* ]]; then
        if ! read -r -p "This will overwrite current station configuration! Continue? [Yes/No]" continue; then
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

    printf "Installing services...\n"
    if ! "$repodir/SEISREC-DIST/scripts/install_services.sh" "INSTALL"; then
      printf "Error installing services! Please fix problems before retrying!\n"
      exit 1
    fi

    printf "Setting up station parameters...\n"
    if ! "$repodir/SEISREC-DIST/util/util_paramedit"; then
      printf "Error setting up station parameters! Please fix problems before retrying!\n"
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
    ;;
  esac


done
printf "Good bye!\n"
exit 0
