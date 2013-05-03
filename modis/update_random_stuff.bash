#!/bin/bash

 . /opt/modis_processing/setup.sh 
/hub/raid/jcable/data/global_aqua/seadas6.2/run/scripts/update_luts.py terra -v
/hub/raid/jcable/data/global_aqua/seadas6.2/run/scripts/update_luts.py aqua -v
