#!/bin/bash

###############################################################################
# Script to generate dataset for SVM
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

URL="wget https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/binary/kdd12.bz2"

if [ ! -e $ROOT/kdd12 ]; then
	echo "Downloading kdd12 dataset..."
	wget -c $URL -P $ROOT
	echo "Download Completed."
	echo "Extracting now. This may take a while..."
	bunzip2 -f $ROOT/kdd12.bz2 > $ROOT/kdd12
else
	echo "Dataset already present..."
fi
