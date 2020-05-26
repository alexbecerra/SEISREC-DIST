# SEISREC-DIST

## Software Download

Copy and burn standard SEISREC debian image to sd card.

Then, run the following commands from the home folder:

```pi@raspberrypi: ~$ git clone https://github.com/alexbecerra/SEISREC-DIST.git```

## Software Installation & Setup
After cloning has completed run:

```pi@raspberrypi: ~$ ./SEISREC-DIST/scripts/SEISREC-config.sh```

For setup, choose option [1], and follow instructions
```
MAIN MENU - SEISREC_config

1) Software Setup & Update  4) Help
2) Station Info & Tests     5) Quit
3) Advanced Options
Selection: 1
``` 
### Station Setup
```
STATION SOFTWARE & UPDATE - SEISREC_config.sh

Station is not set up.
Proceed with station setup? [Yes/Skip] 
```
Setup starts with a software update to latest commit:
```
SYSTEM UPDATE- SEISREC-config.sh

SEISREC-DIST last commit to branch master:

commit fa72327c7e1208443ba5915d17ef659a4e2ae5e9
Author: Ignacio Maldonado <revisiontecnica@gmail.com>
Date:   Mon May 25 18:33:10 2020 -0400

    Added branch info

Press any key to continue...
```

For normal operation, the station parameters must be defined first. Each parameter must be defined in turn.
Parameter descriptions are provided.

```
CONFIGURE STATION PARAMETERS - SEISREC-config.sh

Parameter Edit Utility | Version: ?.? | Hash: a1b2c3d4e5f6g7h8i9k0lmnop | Built by: SEISREC on dd-mm-yy @ hh:ss UTC
Setting sta_name: Nombre de la estacion (Por defecto: DEV00)
Enter value: 

Setting sta_net: Nombre de la red a la cual pertenece la estacion (Por defecto: EEW)
Enter value: EEW
```

After defining parameters, unit services are installed and station software starts.

Finally, if desired, SEISREC-config utility can be added to the standard path and run by typing:
```pi@raspberry:~$ SEISREC-config```