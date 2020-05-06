#!/bin/bash

dir="$HOME/SEISREC-DIST/TEST"

echo " "
echo "Comenzando pruebas de placa ACC355"
sudo "$dir/TEST_ACC355"
echo " "
echo "Comenzando pruebas de placa TIMING"
sudo "$dir/TEST_TIMING"
