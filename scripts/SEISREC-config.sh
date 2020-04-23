#!/bin/bash

param=''
editsingle=''
view=''

# Parse options
while getopts "p:vh" opt; do
  case ${opt} in
    p )
      editsingle="yes"
      param="$OPTARG"
      ;;
    v )
      view='yes'
      ;;
    h )
      echo "Usage: SEISREC-config.sh [options]"
      echo "    [-h]                  Display this help message & exit."
      echo "    [-p] <parameter>      Edit single parameter from configuration file"
      echo "    [-v]                  View config file and exit"
      exit 0
      ;;
   \? )
     echo "Invalid Option: -$OPTARG" 1>&2
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))

PS3='Please enter your choice: '
options=("Option 1" "Option 2" "Option 3" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Option 1")
            echo "you chose choice 1"
            ;;
        "Option 2")
            echo "you chose choice 2"
            ;;
        "Option 3")
            echo "you chose choice $REPLY which is $opt"
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

currdir=`pwd`

cd ~/SEISREC/

if [ ! -z "$view" ]
then
  cat parameter
  exit 0
fi

if [ ! -z "$editsingle" ]
then
  ~/SEISREC/build/bin/param-edit -pth ~/SEISREC/ -param $param
  exit 0
fi

~/SEISREC/build/bin/param-edit -pth ~/SEISREC/

