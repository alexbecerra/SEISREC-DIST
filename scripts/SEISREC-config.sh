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
    printf "Uso: SEISREC-config.sh [opciones]"
    printf "    [-h]                  Muestra este mensaje de ayuda y termina.\n"
    printf "    [-d]                  Habilita mensajes de debug.\n"
    exit 0
    ;;
  \?)
    printf "Opción inválida: -%s" "$OPTARG" 1>&2
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
    printf "Estableciendo parámetros de script_utils.sh ...\n"
  else
    printf "¡Error estableciendo parámetros de script_utils.sh!. Abortando ...\n"
    exit 1
  fi
else
  printf "¡Error obteniendo el directorio de trabajo!. Abortando ...\n"
  exit 1
fi

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
  print_title "CONFIGURACIÓN DE PARÁMETROS DE LA ESTACIÓN - SEISREC-config.sh"
  "$repodir/SEISREC-DIST/util/util_paramedit" "${opts[@]}"
  any_key
}

##################################################################################################################################
# UPDATE SYSTEM SOFTWARE - updates to DIST and DEV software
# ################################################################################################################################
function update_station_software() {
  print_title "ACTUALIZACIÓN DEL SOFTWARE DEL SISTEMA - SEISREC-config.sh"
  # sta_type variable must be defined
  if [ -z "$sta_type" ]; then
    printf "¡Tipo de estación no definido!.\n"
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
    print_title "ACTUALIZACIÓN DE SISTEMA - SEISREC-config.sh"
    # Get last commit to SEISREC-DIST
    if [ -d "$workdir" ]; then
      if ! cd "$workdir"; then
        printf "Error accediendo a %s.\n" "$workdir"
        exit 1
      else
        if git log | head -5 >/dev/null 2>&1; then
          printf "SEISREC-DIST - Último commit a rama %s:\n\n" "$(git branch | grep "\*.*" | sed -e "s/* //")"
          printf "%s\n\n" "$(git log | head -5)"
          version=""
          if git describe --tags >/dev/null 2>&1; then
            version=$(git describe --tags)
          fi
          if [ -n "$version" ]; then
            printf "\nVersión de software: %s.\n" "$version"
          fi
        else
          printf "¡Error obteniendo los logs de git!.\n"
        fi
      fi
    else
      printf "¡No se encontró el directorio de SEISREC-DIST!\n"
      exit 1
    fi
    printf "\n"

    # Get last commit to SEISREC-DEV
    if [ "$sta_type" == "DEV" ]; then
      if [ -d "$workdir/SEISREC-DEV" ]; then
        if ! cd "$workdir/SEISREC-DEV"; then
          printf "Error accediendo a %s.\n" "$workdir/SEISREC-DEV"
          exit 1
        else
          if git log | head -5 >/dev/null 2>&1; then
            printf "\nSEISREC-DEV - Último commit a rama %s:\n\n" "$(git branch | grep "\*.*" | sed -e "s/* //")"
            printf "%s\n\n" "$(git log | head -5)"
            version=""
            if git describe --tags >/dev/null 2>&1; then
              version=$(git describe --tags)
            fi
            if [ -n "$version" ]; then
              printf "\nVersión de software: %s.\n" "$version"
            fi
          else
            printf "¡Error obteniendo los logs de git!.\n"
          fi
        fi
      else
        printf "¡No se encontró el directorio de SEISREC-DEV!.\n"
        exit 1
      fi
    fi
    printf "\n"

    # Select update by version or simple git pull
    PS3='Seleccione: '
    if [ "$sta_type" == "DEV" ]; then
      options=("Versión software DIST" "Versión software DEV" "Actualización manual" "Atrás")
    else
      options=("Versión software DIST" "Actualización manual" "Atrás")
    fi
    select opt in "${options[@]}"; do
      case $opt in
      "Actualización manual")
      # Manual update pulls most recent commit from remote
      print_title "Actualización manual"
        while [ -z "$continue" ]; do
          if ! read -r -p "¿Actualizar estación? [S]i/[N]o. " continue; then
            printf "¡Error leyendo STDIN!. Abortando ...\n"
            exit 1
          elif [[ "$continue" =~ [sS].* ]]; then
            if [ -d "$workdir" ]; then
              if ! cd "$workdir"; then
                printf "Error accediendo a %s.\n" "$workdir"
                exit 1
              fi

              printf "Obteniendo cambios desde el repositorio remoto de SEISREC-DIST ...\n\n"
              git pull

              if [ "$sta_type" == "DEV" ]; then
                if [ -d "$workdir/SEISREC-DEV" ]; then
                  if ! cd "$workdir/SEISREC-DEV"; then
                    printf "Error accediendo a %s/SEISREC-DEV.\n" "$workdir"
                    exit 1
                  fi

                  printf "\nObteniendo cambios desde el repositorio remoto de SEISREC-DEV ...\n\n"
                  git pull
                else
                  printf "¡No se encontró %s/SEISREC-DEV!.\n" "$workdir"
                fi
              fi
            else
              printf "¡No se encontró %s/SEISREC-DEV!.\n" "$workdir"
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

      "Versión software DIST")
        # Print current DIST version
        while [ -z "$continue" ]; do
          print_title "Actualizar versión software DIST"
          if ! cd "$workdir"; then
            printf "¡Error accediendo %s!.\n" "$workdir"
          fi
          if git describe --tags >/dev/null 2>&1; then
            version=$(git describe --tags)
            printf "Versión actual de software DIST: %s.\n" "$version"
          else
            printf "Commit actual no tiene tags.\n"
          fi

          printf "\n"
          if ! read -r -p "¿Cambiar la versión del software DIST? [S]i/[N]o " continue; then
            printf "¡Error leyendo STDIN!. Abortando ...\n"
            exit 1
          elif [[ "$continue" =~ [sS].* ]]; then
            # Get and print list of tags to checkout
            versionlist=$(git tag -l)
            if [ -z "$versionlist" ]; then
              printf "¡No se encontraron versiones!.\n"
              any_key
              break
            fi

            PS3='Seleccione versión: '
            options=()
            for f in $(printf "%s" "$versionlist" | sed -e 's/$version\n//'); do
              options+=( "$f" )
            done
            options+=( "Salir" )
            select opt in "${options[@]}"; do
              if [ -n "$debug" ]; then
                printf "opt = %s\n" "$opt"
              fi

              # Try checking out tag
              if [ "$opt" == "Salir" ]; then
                  break
              elif ! "git checkout tags/$opt"; then
                printf "¡Error actualizando el software!.\n"
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

      "Versión software DEV")
        # Print current DEV version
        while [ -z "$continue" ]; do
          print_title "Actualizar versión del software DEV"
          if [ "$sta_type" != "DEV" ]; then
            printf "¡Error en el tipo de estación!.\n"
            exit 1
          fi

          if ! cd "$workdir/SEISREC-DEV"; then
            printf "¡Error accediendo %s!.\n" "$workdir"
          fi
          if git describe --tags >/dev/null 2>&1; then
            version=$(git describe --tags)
          printf "Actual versión del software DEV: %s.\n" "$version"
          else
            printf "Commit actual no tiene tags.\n"
          fi
          printf "\n"

          if ! read -r -p "¿Cambiar versión del software DEV? [S]i/[N]o " continue; then
            printf "¡Error leyendo STDIN!. Abortando ...\n"
            exit 1
          elif [[ "$continue" =~ [sS].* ]]; then
            # Get and print list of tags to checkout
            versionlist=$(git tag -l)
            if [ -z "$versionlist" ]; then
              printf "¡No se encontraron versiones!.\n"
              any_key
              break
            fi

            PS3='Seleccione versión del software DEV: '
            options=()
            for f in $(printf "%s" "$versionlist" | sed -e 's/$version\n//'); do
              options+=( "$f" )
              #TODO[0]: ¿Falta agregar acá un options += ("Salir")?
              #options+=( "Salir" )
            done
            select opt in "${options[@]}"; do
              if [ -n "$debug" ]; then
                printf "opt = %s" "$opt"
              fi

              # Try checking out tag
              if [ "$opt" == "Salir" ]; then
                  break
              elif ! "git checkout tags/$opt"; then
                printf "¡Error actualizando el software!.\n"
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

      "Atrás")
        answered="yes"
        break
        ;;
      esac
    done
  done

  if [ -d "$currdir" ]; then
    if ! cd "$currdir"; then
      printf "Error accediendo a %s.\n" "$currdir"
      exit 1
    fi
  else
    printf "¡No se encontró el directorio %s!.\n" "$currdir"
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
    print_title "CONFIGURACIÓN DE SERVICIOS - SEISREC_config.sh"

    # Get enabled services
    enabled_services=$(systemctl list-unit-files)

    # Get SEISREC services
    services=$(ls "$repodir/SEISREC-DIST/services")
    printf "\nEstado de los servicios:\n"
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
      printf "\nSeleccione servicios para su configuración: "
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
    PS3='Seleccione: '
    options=("Iniciar" "Detener" "Deshabilitar" "Limpiar" "Instalar" "Seleccionar servicios" "Atrás")
    select opt in "${options[@]}"; do
      case $opt in
      "Iniciar")
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
      "Detener")
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
      "Deshabilitar")
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
      "Limpiar")
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
      "Instalar")
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
      "Seleccionar servicios")
        printf "%s" "$(ls $repodir/SEISREC-DIST/services | grep ".*.service")" >>"$workdir/available_services.tmp"
        select_several_menu "SELECCIONAR SERVICIOS - SEISREC-config.sh" "$workdir/available_services.tmp" "$workdir/selected_services_file.tmp"
        break
        ;;
      "Atrás")
        answered="yes"
        printf "Limpiando y saliendo ...\n"
        clean_up "$workdir/available_services.tmp"
        clean_up "$workdir/selected_services_file.tmp"
        if [ -n "$debug" ]; then
          printf "¡Hasta luego!.\n"
        fi
        break
        ;;
      *)
        printf "Opción inválida %s.\n" "$REPLY"
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
  print_title "INFORMACIÓN DETALLADA DEL SOFTWARE - SEISREC-config.sh"

  if [ -z "$sta_type" ]; then
    printf "¡Tipo de estación no definido!.\n"
    exit 1
  fi

  # Get current working directory for return point
  local currdir=$(pwd)

  if [ -d "$workdir" ]; then
    if ! cd "$workdir"; then
      printf "Error accediendo a %s.\n" "$workdir"
      exit 1
    else
      # Get last commit info
      if git log | head -5 >/dev/null 2>&1; then
        printf "SEISREC-DIST - Último commit a rama %s:\n\n" "$(git branch | grep "\*.*" | sed -e "s/* //")"
        printf "%s" "$(git log | head -5)"
      else
        printf "¡Error obteniendo logs de git!.\n"
      fi
    fi
  else
    printf "¡No se encontró SEISREC-DIST!\n"
    exit 1
  fi
  printf "\n"
  if [ "$sta_type" == "DEV" ]; then
    if [ -d "$workdir/SEISREC-DEV" ]; then
      if ! cd "$workdir/SEISREC-DEV"; then
        printf "Error accediendo a %s.\n" "$workdir/SEISREC-DEV"
        exit 1
      else
        # Get last commit info
        if git log | head -5 >/dev/null 2>&1; then
          printf "SEISREC-DEV - Último commit a rama %s:\n\n" "$(git branch | grep "\*.*" | sed -e "s/* //")"
          printf "%s\n\n" "$(git log | head -5)"
        else
          printf "¡Error obteniendo logs de git!.\n"
        fi
      fi
    else
      printf "¡No se encontró el directorio de SEISREC-DEV!.\n"
      exit 1
    fi
  fi

  # Display Info

  print_exec_versions

  printf "Versiones de software instalados:\n\n"

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
      printf "Error accediendo a %s.\n" "$currdir"
      exit 1
    fi
  else
    printf "¡No se encontró el directorio %s!.\n" "$currdir"
  fi

  any_key
}

##################################################################################################################################
# STATION SETUP FUNCTION
# ################################################################################################################################
function setup_station() {
  local cfgeverywhere=""

  print_title "CONFIGURACIÓN DE ESTACIÓN - SEISREC-config.sh"

  printf "Preparando configuración ...\n"
  printf "Chequendo actualizaciones ...\n"
  # Update Station software
  update_station_software

  printf "Configurando parámetros de la estación ...\n"
  # Set up station parameters for operation
  configure_station

  # Install Services after configuring parameters
  printf "Instalando servicios ...\n"
  local opts=("INSTALL")
  if [ -n "$debug" ]; then
    opts+=(-d)
  fi
  if ! "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"; then
  #TODO[4]: Especificar problemas a correjir antes de reintentar
    printf "¡Error instalando servicios!. Por favor, corrija problemas antes de reintentar.\n"
    exit 1
  fi

  # Prompt for installing SEISREC-config utility
  if ! read -r -p "¿Instalar SEISREC-config en el PATH del sistema? [S]i/[N]o" continue; then
    printf "¡Error leyendo STDIN!. Abortando ...\n"
    exit 1
  elif [[ "$continue" =~ [sS].* ]]; then
    cfgeverywhere="yes"
  elif [[ "$continue" =~ [nN].* ]]; then
    cfgeverywhere=""
  fi

  if [ -n "$cfgeverywhere" ]; then
    # if symlink to SEISREC-config doesn't exist, create it
    if [ ! -h "$repodir/SEISREC-DIST/SEISREC-config" ]; then
      printf "Creando enlaces simbólicos a SEISREC-config ...\n"
      ln -s "$repodir/SEISREC-DIST/scripts/SEISREC-config.sh" "$repodir/SEISREC-DIST/SEISREC-config"
    fi

    if ! cp "$HOME/.bashrc" "$HOME/.bashrc.bak"; then
      printf "¡Error haciendo copia de seguridad del archivo .bashrc!.\n"
    fi

    # Check if ~/SEISREC is in PATH, if not, add it to PATH
    inBashrc=$(cat "$HOME/.bashrc" | grep 'SEISREC-DIST')
    inPath=$(printf "%s" "$PATH" | grep 'SEISREC-DIST')
    if [ -z "$inBashrc" ]; then
      if [ -z "$inPath" ]; then
        # Add it permanently to path
        printf "Agregando ./SEISREC-DIST a PATH...\n"
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
  print_title "CONVERSIÓN DE $sta_type A $other_sta_type - SEISREC_config"
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
    print_title "CONFIGURACIÓN SERVICIO NTP - SEISREC_config"

    local opts=()
    if [ -n "$debug" ]; then
      opts+=(-d)
    fi
    PS3='Selection: '
    options=("Editar archivo de configuración de NTP" "Cargar archivo de configuración de NTP desde la distribución" "Ver archivo de configuración de NTP" "Atrás")
    select opt in "${options[@]}"; do
      case $opt in
      "Editar archivo de configuración de NTP")
        if [ -f "/etc/ntp.conf" ]; then
          if ! sudo nano /etc/ntp.conf; then
            printf "¡Error editando /etc/ntp.conf!.\n"
          fi
        else
          printf "¡No se pudo encontrar /etc/ntp.conf!.\n"
        fi
        break
        ;;
      "Cargar archivo de configuración de NTP desde la distribución")
        local ans
        while [ -z "$continue" ]; do
          if ! read -r -p "Esta acción sobreescribirá COMPLETAMENTE el archivo ntp.conf existente. ¿Desea continuar? [S]i/[N]o" continue; then
            printf "¡Error leyendo STDIN!. Abortando ...\n"
            exit 1
          elif [[ "$continue" =~ [sS].* ]]; then
            if [ -f "/etc/ntp.conf" ]; then
              if ! sudo rm "/etc/ntp.conf"; then
                printf "!Error removiendo /etc/ntp.conf!.\n"
              fi
            fi
            if ! cp "$workdir/sysfiles/ntp.conf" "/etc/ntp.conf"; then
              printf "¡Error copiando /etc/ntp.conf!.\n"
              any_key
            fi
            break
          #TODO[3]: la opción [sS], ¿está bien aquí?
          elif [[ "$continue" =~ [sS].* ]]; then
            break
          else
            continue=""
          fi
        done
        break
        ;;
      "Ver archivo de configuración de NTP")
        if [ -f "/etc/ntp.conf" ]; then
          if ! sudo cat "/etc/ntp.conf"; then
            printf "¡Error al leer /etc/ntp.conf!.\n"
          fi
        else
          printf "¡No se pudo encontrar /etc/ntp.conf!.\n"
        fi
        any_key
        break
        ;;
      "Atrás")
        answered="yes"
        break
        ;;
      *)
        printf "Opción inválida %s.\n" "$REPLY"
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
    print_title "CONFIGURACIÓN DE REDES - SEISREC_config"

    local opts=()
    if [ -n "$debug" ]; then
      opts+=(-d)
    fi
    PS3='Seleccione: '
    options=("Configurar dirección IP de la interfaz" "Configurar prioridades de las interfaces" "Atrás")
    select opt in "${options[@]}"; do
      case $opt in
      "Configurar dirección IP de la interfaz")
        under_construction
        # TODO: Write IP config function
        any_key
        break
        ;;
      "Configurar prioridades de las interfaces")
        if [ -f "$workdir/sysfiles/dhcpcd.conf" ]; then
          if ! sudo nano "$workdir/sysfiles/dhcpcd.conf"; then
            printf "¡Error editando %s/sysfiles/dhcpcd.conf!.\n" "$workdir"
            any_key
          fi
        else
          printf "¡No se pudo encontrar %s/sysfiles/dhcpcd.conf!.\n" "$workdir"
          any_key
        fi
        break
        ;;
      "Atrás")
        answered="yes"
        break
        ;;
      *)
        printf "Opción inválida %s.\n" "$REPLY"
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
  print_title "REPORTE DE RENDIMIENTO - SEISREC_config"
  # TODO: write performance tests
  under_construction
  any_key
}
##################################################################################################################################
# UNINSTALL SEISREC
# ################################################################################################################################
function uninstall_seisrec() {
  print_title "DESINSTALAR SOFTWARE SEISREC - SEISREC_config"
  local currdir=$(pwd)

  if [ -n "$(pwd | grep "SEISREC-DIST")" ]; then
    if [ -n "$debug" ]; then
      printf "El directorio de trabajo actual está dentro de SESIREC-DIST"
    fi
    cd "$HOME"
  fi

  local opts=()
  if [ -n "$debug" ]; then
    opts+=(-d)
  fi
  while [ -z "$continue" ]; do
    if ! read -r -p "Esta acción DESINSTALARÁ POR COMPLETO el software SEISREC. ¿Desea continuar? [S]i/[N]o " continue; then
      printf "¡Error leyendo STDIN!. Abortando ...\n"
      exit 1
    elif [[ "$continue" =~ [sS].* ]]; then
      choice="disable"
      opts+=(-n "$choice")
      if ! "$repodir/SEISREC-DIST/scripts/install_services.sh" "${opts[@]}"; then
        printf "¡Error deshabilitando servicios!.\n"
      fi

      if ! rm "$HOME/.bashrc"; then
        printf "¡Error removiendo el archivo .bashrc!.\n"
      fi

      if ! mv "$HOME/.bashrc.bak" "$HOME/.bashrc"; then
        printf "¡Error restaurando el archivo .bashrc original!.\n"
      fi

      export PATH=$(printf "%s" "$PATH" | sed -e "s|$repodir/SEISREC-DIST:||")

      if ! sudo rm -r "$repodir/SEISREC-DIST/"; then
        printf "¡Error removiendo el repositorio de SEISREC-DIST!.\n"
        exit 1
      fi

      printf "Para reinstalar el software, clonar desde el siguiente repositorio https://github.com/alexbecerra/SEISREC-DIST.git\n"
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
      printf "¡Error accediendo al directorio de SEISREC-DEV!.\n"
    fi
    reponame=$(basename $(git rev-parse --show-toplevel))
    if [ "$reponame" == "SEISREC-DEV" ]; then
      sta_type="DEV"
      other_sta_type="DIST"
    else
      printf "Directorio SEISREC-DEV está presente pero tiene un repositorio incorrecto.\n"
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
  print_title "MENÚ PRINCIPAL - SEISREC_config"
  PS3='Seleccione: '
  options=("Configuración y actualización de software" "Información y pruebas de la estación" "Opciones avanzadas" "Salir")
  select opt in "${options[@]}"; do
    case $opt in
    "Opciones avanzadas")
      choice="Opciones avanzadas"
      break
      ;;
    "Información y pruebas de la estación")
      choice="Información y pruebas de la estación"
      break
      ;;
    "Configuración y actualización de software")
      choice="Configuración y actualización de software"
      break
      ;;
    "Salir")
      printf "¡Hasta luego!.\n"
      exit 0
      ;;
    *)
      printf "Opción inválida %s.\n" "$REPLY"
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
  "Opciones avanzadas")
    done=""
    if [ ! -f "$repodir/SEISREC-DIST/parameter" ]; then
      printf "No se encontró archivo de parámetros válidos. Por favor, ejecute la configuración de la estación primero.\n"
      any_key
    else
      while [ -z "$done" ]; do
        check_sta_type

        print_title "CONFIGURACION DE SOFTWARE DE LA ESTACION - SEISREC_config.sh"
        if [ "$sta_type" == "DEV" ]; then
          options=("Configurar parámetros de la estación" "Configurar servicios" "Configurar redes" "Configurar NTP" "Convertir a $other_sta_type" "Compilar software de la estación" "Atrás")
        else
          options=("Configurar parámetros de la estación" "Configurar servicios" "Configurar redes" "Configurar NTP" "Convertir a $other_sta_type" "Atrás")
        fi
        select opt in "${options[@]}"; do
          case $opt in
          "Configurar parámetros de la estación")
            configure_station
            break
            ;;
          "Configurar servicios")
            manage_services
            break
            ;;
          "Configurar redes")
            manage_networks
            break
            ;;
          "Convertir a $other_sta_type")
            dist2dev
            break
            ;;
          "Compilar software de la estación")
            SEISREC-build
            break
            ;;
          "Configurar NTP")
            manage_ntp
            break
            ;;
          "Atrás")
            done="yes"
            break
            ;;
          *)
            printf "Opción inválida %s.\n" "$REPLY"
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
  "Información y pruebas de la estación")
    done=""
    while [ -z "$done" ]; do
      print_title "INFORMACIÓN Y PRUEBAS DE LA ESTACIÓN - SEISREC_config.sh"
      options=("Ejecutar pruebas de la estación" "Información detallada del software" "Reporte de rendimiento" "Atrás")
      select opt in "${options[@]}"; do
        case $opt in
        "Ejecutar pruebas de la estación")
          "$repodir/SEISREC-DIST/scripts/SEISREC-TEST.sh"
          any_key
          break
          ;;
        "Información detallada del software")
          get_software_info
          break
          ;;
        "Reporte de rendimiento")
          performance_report
          break
          ;;
        "Atrás")
          done="yes"
          break
          ;;
        *)
          printf "Opción inválida %s.\n" "$REPLY"
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
  "Configuración y actualización de software")
    done=""
    while [ -z "$done" ]; do
      continue=""
      print_title "CONFIGURACIÓN DE LA ESTACIÓN - SEISREC_config.sh"
      if [ ! -f "$repodir/SEISREC-DIST/parameter" ]; then
        printf "La estación no está configurada.\n"
        while [ -z "$continue" ]; do
          if ! read -r -p "¿Proceder con la configuración de la estación? [S]i/[O]mitir " continue; then
            printf "¡Error leyendo STDIN!. Abortando ...\n"
            exit 1
          elif [[ "$continue" =~ [sS].* ]]; then
            setup_station
          elif [[ "$continue" =~ [oO].* ]]; then
            break
          else
            continue=""
          fi
        done
      fi
      print_title "CONFIGURACIÓN y ACTUALIZACIÓN DE SOFTWARE - SEISREC_config.sh"

      options=("Versión y actualización de SEISREC" "Configuración de la estación" "Desinstalación" "Atrás")
      select opt in "${options[@]}"; do
        case $opt in
        "Versión y actualización de SEISREC")
          update_station_software
          break
          ;;
        "Configuración de la estación")
          if [ -f "$repodir/SEISREC-DIST/parameter" ]; then
            printf "Parece que la estación ya está configurada.\n"
            if ! read -r -p "¿Desea reconfigurar estación desde el inicio? [S]i/[N]o " continue; then
              printf "¡Error leyendo STDIN! Abortando ...\n"
              exit 1
            elif [[ "$continue" =~ [sS].* ]]; then
              if ! read -r -p "Esta acción SOBREESCRIBIRÁ la configuración actual de la estación. ¿Desea continuar? [S]i/[N]o" continue; then
                printf "¡Error leyendo STDIN! Abortando ...\n"
                exit 1
              elif [[ "$continue" =~ [sS].* ]]; then
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
        "Desinstalación")
          uninstall_seisrec
          break
          ;;
        "Atrás")
          done="yes"
          break
          ;;
        *)
          printf "Opción inválida %s.\n" "$REPLY"
          break
          ;;
        esac
      done
    done
    done=""
    ;;
  esac
done
printf "¡Hasta luego!.\n"
exit 0
