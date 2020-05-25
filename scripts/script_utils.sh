##################################################################################################################################
# PRINT TITLE FUNCTION
# ################################################################################################################################
function print_banner() {
  printf "                                                                             \n"
  printf "███████╗███████╗██╗    ██╗       ██████╗███████╗███╗   ██╗\n"
  printf "██╔════╝██╔════╝██║    ██║      ██╔════╝██╔════╝████╗  ██║\n"
  printf "█████╗  █████╗  ██║ █╗ ██║█████╗██║     ███████╗██╔██╗ ██║\n"
  printf "██╔══╝  ██╔══╝  ██║███╗██║╚════╝██║     ╚════██║██║╚██╗██║\n"
  printf "███████╗███████╗╚███╔███╔╝      ╚██████╗███████║██║ ╚████║\n"
  printf "╚══════╝╚══════╝ ╚══╝╚══╝        ╚═════╝╚══════╝╚═╝  ╚═══╝\n"
}

##################################################################################################################################
# Prints "under construction" banner
# ################################################################################################################################
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
# Clears screen and prints title
# ################################################################################################################################
function print_title() {
  if [ -n "$debug" ]; then
    if [ -n "$(type -t cls)" ]; then
      printf "cls func present\n"
    fi
    if [ -n "$(type -t clear)" ]; then
      printf "clear func present\n"
    fi
  fi
  if [ -z "$debug" ]; then
    if [ -n "$(type -t cls)" ]; then
      if ! cls; then
        printf "D'OH"
      fi
    elif [ -n "$(type -t clear)" ]; then
      if ! clear; then
        printf "D'OH"
      fi
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
# Cleans up target file
# ################################################################################################################################
function clean_up() {
  local file
  file="$1"
  if [ -f "$file" ]; then
    if [ -n "$debug" ]; then
      printf "Removing %s\n" "$file"
    fi
    if ! rm "$file" >/dev/null 2>&1; then
      printf "Error removing %s\n" "$file"
    fi
  fi
}


##################################################################################################################################
# Press any key to continue func
# ################################################################################################################################
function any_key() {
  read -n 1 -r -s -p $'Press any key to continue...\n'
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
  if [ -d "$workdir" ]; then
    tempfiles=$(ls "$workdir" | grep ".*.tmp")
    if [ -n "$debug" ]; then
      printf "tempfiles = %s\n" "$tempfiles"
    fi
    listfiles=$(ls "$workdir" | grep ".*.list")
    if [ -n "$debug" ]; then
      printf "listfiles = %s\n" "$listfiles"
    fi
    for l in $listfiles; do
      clean_up "$l"
    done
    for t in $tempfiles; do
      clean_up "$t"
    done
    exit 1
  fi
}

##################################################################################################################################
# Creates a variable element menu selection
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

  if [ -n "$debug" ]; then
    printf "menu_title = %s " "$menu_title"
    printf "menu_opts_file = %s " "$menu_opts_file"
    printf "selected_names_file = %s " "$selected_names_file"
  fi

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

  if [ -n "$debug" ]; then
    printf "optionnames = %s " "${optionnames[@]}"
    printf "\n"
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
