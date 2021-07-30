#!/bin/bash

BENCHMARKS="xsbench gups svm redis btree graph500 memcached canneal"
CONFIGS="2MBTHP-F TRIDENT-F" #HAWKEYE-F
# -- For HAWKEYE-F, boot system with HawkEye and uncomment the following line
#CONFIGS="HAWKEYE-F"

SCRIPTS=$(dirname `readlink -f "$0"`)
ROOT="$(dirname "$SCRIPTS")"
source $SCRIPTS/common.sh
source $SCRIPTS/configs.sh

for BENCHMARK in $BENCHMARKS; do
	for CONFIG in $CONFIGS; do
		cleanup_system_configs
		setup_4kb_configs
		fragment_memory
		prepare_args
		prepare_system_configs
		prepare_paths
		launch_workload
	done
done
