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
  exit 0
}

configure_station() {
  print_help
}

update_station_software() {
  print_help
}

create_menu() {
  unset menu_opts
  unset menu_prompt
  unset answered

  menu_prompt="$1"
  menu_opts="$2"

  printf "\n%s\n" "$"
  while [ -z "$answered" ]; do
        servicenames=()
        for s in $justservices; do
          sname=$(printf "%s" "$s" | sed -e "s/.service//")
          servicenames+=("$sname")
        done

        while [ -z "$answered" ]; do
          printf "\nAvailable services:\n"
          indx=1
          for n in "${servicenames[@]}"; do
            printf " [%i]\t%s\n" "${indx}" "$n"
            indx=$((indx + 1))
          done
          printf " [0]\tAll services \n"

          service=""
          printf "Please select services: "
          read -r service
          for m in $service; do
            if [[ "$m" =~ ^[0-9]$ ]]; then
              if [ -n "$debug" ]; then
                printf "%s input accepted\n" "$m"
              fi
              servicesToManage+=("$((m - 1))")
            else
              if [ -n "$debug" ]; then
                printf "%s input rejected\n" "$m"
              fi
            fi
          done

          for n in "${servicesToManage[@]}"; do
            if [ "$n" -eq -1 ]; then
              servicesToManage=()
              indx=1
              for s in "${servicenames[@]}"; do
                servicesToManage+=("$((indx - 1))")
                indx=$((indx + 1))
              done
              break
            fi
          done

          printf "\nServices selected: "
          for n in "${servicesToManage[@]}"; do
            printf "%s " "${servicenames[$((n))]}"
          done

          #---------------------------------------------------------------
          # CONFIG CONFIRMATION
          #---------------------------------------------------------------
          printf "\nSelecting: [C]ontinue [R]eselect [A]bort ? "
          if ! read -r continue; then
            printf "Error reading STDIN! Aborting...\n"
            exit 1
          elif [[ "$continue" =~ [cC].* ]]; then
            answered="yes"
            if [ -f "$repodir/SEISREC-DIST/service.build.list" ]; then
              if [ -n "$debug" ]; then
                printf "Removing service.build.list\n"
              fi
              if ! rm "$repodir/SEISREC-DIST/service.build.list"; then
                printf "Error removing service.build.list!\n"
              fi
            else
              if [ -n "$debug" ]; then
                printf "Creating service.build.list\n"
              fi
              if ! touch "$repodir/SEISREC-DIST/service.build.list"; then
                printf "Error creating service.build.list!\n"
              fi
            fi

            for n in "${servicesToManage[@]}"; do
              if [ -n "$debug" ]; then
                printf "Appending %s to service.build.list\n" "${servicenames[$((n))]}"
              fi
              printf "%s\n" "${servicenames[$((n))]}.service" >>"$repodir/SEISREC-DIST/service.build.list"
            done

            break
          elif [[ "$continue" =~ [rR].* ]]; then
            printf "Reselecting...\n"
          elif [[ "$continue" =~ [aA].* ]]; then
            answered="abort"
            printf "Cleaning up & exiting...\n"
            if [ -f "$repodir/SEISREC-DIST/service.build.list" ]; then
              if [ -n "$debug" ]; then
                printf "Removing service.build.list\n"
              fi
              if ! rm "$repodir/SEISREC-DIST/service.build.list"; then
                printf "Error removing service.build.list!\n"
              fi
            fi
            if [ -n "$debug" ]; then
              printf "Bye bye!\n"
            fi
          else
            printf "\n[C]ontinue [R]eselect [A]bort ? "
          fi
        done
        break
        ;;
      "Back")
        choise="back"
        break
        ;;
      *) printf "invalid option %s\n" "$REPLY" ;;
      esac


    if [ -n "$debug" ]; then
      printf "choise = %s\n" "$choise"
      debugflag="-d"
    fi

    install_services_args=( "$debugflag" "$choise" )

    if [ -n "$choise" ]; then
      if [ -f "$repodir/SEISREC-DIST/service.build.list" ]; then
        install_services_args+=( "-f $\"$repodir/SEISREC-DIST/service.build.list\"" )
      fi
        "$repodir/SEISREC-DIST/scripts/install_services.sh" "${install_services_args[@]}"
    fi

    if [ -f "$repodir/SEISREC-DIST/service.build.list" ]; then
      printf "Removing service.build.list...\n"
      if ! rm "$repodir/SEISREC-DIST/service.build.list"; then
        printf "Error removing service.build.list!\n"
      fi
    fi
done
choise=""
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
    if [ ! -f "$repodir/SEISREC-DIST/parameter" ]; then
      printf "No parameter file found! Please run station setup first!\n"
    else
      done=""
      while [ -z "$done" ]; do
        printf "\n"
        options=("Configure Station Parameters" "Manage Unit Services" "Help" "Back")
        select opt in "${options[@]}"; do
          case $opt in
          "Configure Station Parameters")
            configure_station
            break
            ;;
          "Manage Unit Services")
            start_stop_services
            break
            ;;
          "Update Station Software")
            update_station_software
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
