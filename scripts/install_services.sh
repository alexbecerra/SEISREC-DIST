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
  printf "Uso: install_services.sh [opciones] <modo>\n"
  printf "    [-h]                  Muestra este mensaje de ayuda.\n"
  printf "    [-f]                  Archivo con la lista de servicios para crear/instalados.\n"
  printf "    [-d]                  Debug.\n"
  printf "    [-n]                  Ejecuta sin preguntar al usuario.\n"
  printf "\nModos:\n"
  printf "  START: Inicia todos los servicios.\n"
  printf "  STOP: Detiene todos los servicios.\n"
  printf "  DISABLE: Detiene y deshabilita todos los servicios.\n"
  printf "  CLEAN: Detiene y deshabilita los servicios y remueve todos los enlaces simbólicos.\n"
  printf "  INSTALL: Detiene y deshabilita los servicios. Remueve todos los enlaces simbólicos. Instala y rehabilita los servicios.\n"
  exit 0
}
while getopts ":hf:dn" opt; do
  case ${opt} in
  h)
    print_help
    ;;
  f)
    fileList="$OPTARG"
    if [ -n "$debug" ]; then
      printf "fileList = %s \n" "$fileList"
    fi
    ;;
  d)
    debug="yes"
    if [ -n "$debug" ]; then
      printf "DEBUG ON! \n"
    fi
    ;;
  n)
    noprompt="yes"
    ;;
  \?)
    printf "Opción inválida: -%s" "$OPTARG" 1>&2
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
    printf "Argumento inválido: -%s." "$PARAM" 1>&2
    exit 1
    ;;
  esac
  shift
done
unset PARAM

if [ -z "$repodir" ]; then
  if [ -n "$debug" ]; then
    printf "¡repodir vacío!.\n"
  fi
  repodir="$HOME"
fi

# Let the user know the script started
printf "install_services.sh - SEISREC utilidad de instalación de servicios\n"

if [ -n "$noprompt" ]; then
  # Print warning, this should be optional
  printf "Este script modificará los servicios activos de SEISREC. ¿Continuar? [S]i/[N]o: "
  # Get answer
  answered=""
  while [ -z "$answered" ]; do
    if ! read -r continue; then
      printf "¡Error leyendo STDIN!. Abortando ...\n"
      exit 1
    elif [[ "$continue" =~ [sS].* ]]; then
      answered="yes"
      break
    elif [[ "$continue" =~ [nN].* ]]; then
      answered="no"
      break
    else
      printf "\n¿Continuar? [S]i/[N]o: "
    fi
  done

  # Let the user know the script has started 100% for real now
  if [ "$answered" == "yes" ]; then
    printf "Iniciando script ...\n"
  else
    printf "Terminando script.\n"
    exit 1
  fi
fi
answered=""

if ! sudo systemctl daemon-reload; then
  printf "¡Error cargando los servicios! Abortando ...\n"
  exit 1
fi

if [ -n "$debug" ]; then
  printf "fileList = %s\n" "$fileList"
fi

# List all services & timers in the services directory
printf "Obteniendo lista de servicios ...\n"
if [ -n "$fileList" ]; then
  if [ -f "$fileList" ]; then
    services=$(cat "$fileList")
    if [ -n "$debug" ]; then
      printf "services = %s" "$services"
      printf "¡fileList encontrado!\n"
    fi
  else
    if [ -n "$debug" ]; then
      printf "¡No se encontró fileList!. Cargando todos los servicios ...\n"
    fi
    services=$(ls "$repodir/SEISREC-DIST/services/")
  fi
else
  services=$(ls "$repodir/SEISREC-DIST/services/")
fi

if [ -n "$debug" ]; then
  printf "servicios = %s\n" "$services"
fi

justservices=$(printf "%s " "$services" | grep ".*.service")
if [ -f "$repodir/SEISREC-DIST/sysfiles/service_init_list" ]; then
  servicegraph=$(cat "$repodir/SEISREC-DIST/sysfiles/service_init_list")
  ordered_services=()
  for s in $servicegraph; do
    for t in $justservices; do
      if [ "$s" == "$t" ]; then
        if [ -n "$debug" ]; then
          printf "t = %s\n" "$t"
        fi
        ordered_services+=("$t")
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
      ordered_services+=("$t")
    fi
  done

  if [ -n "$debug" ]; then
    printf "ordered_services = "
    for f in "${ordered_services[@]}"; do
      printf "%s " "$f"
      printf "\n"
    done
  fi

else
  ordered_services=()
  for s in $justservices; do
    ordered_services+=("$s")
  done
fi

if [ -n "$startstop" ]; then
  tempstring=""
  case $startstop in
  "start")
    tempstring="Iniciando"
    ;;
  "stop")
    tempstring="Terminando"
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
    printf "Deshabilitando %s ...\n" "$s"
    if ! sudo systemctl disable "$s"; then
      printf "¡Error deshabilitando %s!.\n" "$s"
    fi
  done
fi

# If -r option is used, remove services
if [ -n "$re" ]; then
  printf "Removiendo archivos de servicios instalados ...\n"
  for f in $services; do
    if [ -h "/etc/systemd/system/$f" ]; then
      printf "Removiendo %s ...\n" "$f"
      if ! sudo rm "/etc/systemd/system/$f"; then
        printf "¡Error removiendo %s!.\n" "$f"
      fi
    else
      if [ -n "$debug" ]; then
        printf "No hay instalación previa de %s.\n" "$f"
      fi
    fi
  done
fi

if [ -n "$install" ]; then
  # Let the user know what versions are installed
  printf "Instalando servicios ...\n"

  if [ ! -d "$repodir/SEISREC-DIST/unit/" ]; then
    printf "¡No se encontró el directorio de la unidad ejecutable!. Abortando ...\n"
    exit 1
  fi

  # Install services
  for f in $services; do
    # if symlink exists => service already installed
    if [ ! -f "/etc/systemd/system/$f" ]; then
      # Install only if corresponding unit executable exists
      unitname=$(printf "%s" "$f" | sed -e "s/.service//")
      if [ -z "$(ls "$repodir/SEISREC-DIST/unit/" | grep "$unitname")" ]; then
        printf "¡No hay una unidad ejecutable correspondiente para %s!.\n" "$f"
      fi

      if [ "$repodir" != "/home/pi" ]; then
        if [ -z "$(grep "=$repodir/SEISREC-DIST" "$repodir/SEISREC-DIST/services/$f")" ]; then
          if ! sed -i "s|/.*/SEISREC-DIST|$repodir/SEISREC-DIST|" "$repodir/SEISREC-DIST/services/$f"; then
            printf "¡Error estableciendo la ruta de las unidades ejecutables en %s!.\n" "$f"
          fi
        fi
      fi

      printf "Instalando %s...\n" "$f"
      # Create symlink to service in /etc/systemd/system/
      if ! sudo ln -s "$repodir/SEISREC-DIST/services/$f" "/etc/systemd/system/"; then
        printf "¡Error creando el enlace simbólico para %s!. Omitiendo ...\n" "$f"
        continue
      fi
    else
      # if already installed, notify and abort
      printf "¡%s ya instalado!. Abortando ...\n" "$f"
    fi
  done

  if ! sudo systemctl daemon-reload; then
    printf "¡Error cargando los servicios! Abortando ...\n"
    exit 1
  fi
  # enable after all services have been installed

  for f in "${ordered_services[@]}"; do
    if ! sudo systemctl enable "$f"; then
      printf "¡Error habilitando %s!. Omitiendo ...\n" "$f"
      continue
    fi
  done

  #for f in "${ordered_services[@]}"; do
  #  if ! sudo systemctl start "$f"; then
  #    printf "¡Error iniciando %s!. Omitiendo ...\n" "$f"
  #    continue
  #  fi
  #done

fi

printf "Instalación de servicios completada exitósamente.\n"
