#!/bin/bash

###############################################################################
# Script to generate dataset for canneal (from PARSEC suite)
# 
# nuKSM: NUMA-aware Memory De-duplication for Multi-socket Servers
# Authors: Akash Panda, Ashish Panwar and Arkaprava Basu
# 
###############################################################################

if [ $# -eq 2 ] && [ $2 != "--no-verbose" ]; then
	echo "************************************************************************"
	echo "MICRO'21 - Artifact Evaluation - nuKSM - DATASET PREPARATION"
	echo "************************************************************************"
fi

ROOT=$(dirname `readlink -f "$0"`)
OUT=$ROOT/canneal_small

if [ -e $OUT ]; then
	# already present
	exit
fi

SRC_SCRIPT="$ROOT/canneal_netlist.pl"

URL_SCRIPT="https://parsec.cs.princeton.edu/download/other/canneal_netlist.pl"
if [ ! -e $SRC_SCRIPT ]; then
    echo "Canneal gen script is missing. Downloading it now..."
    wget $URL_SCRIPT -P $ROOT/
    if [ $? -ne 0 ]; then
        echo "error in downloading canneal gen script"
        exit
    fi
fi

chmod +x $SRC_SCRIPT
echo "Preparing small dataset. This will take a while..."
$SRC_SCRIPT 10000 11000 100000000 > $OUT
echo "Dataset is ready now..."
