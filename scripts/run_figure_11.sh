#!/bin/bash

BENCHMARKS="xsbench gups svm redis btree graph500 memcached canneal pr cc bc cg"
# -- To execute with HAWKEYE, boot your system with HAWKEYE kernel image
CONFIGS="TRIDENT-1G TRIDENT-NC TRIDENT-1GF TRIDENT-NCF" # -- reuse 2MBTHP and TRIDENT from Figure-9

SCRIPTS=$(dirname `readlink -f "$0"`)
ROOT="$(dirname "$SCRIPTS")"
source $SCRIPTS/common.sh
source $SCRIPTS/configs.sh

for BENCHMARK in $BENCHMARKS; do
	for CONFIG in $CONFIGS; do
		cleanup_system_configs
		setup_4KB_configs
		fragment_memory
		prepare_args
		prepare_system_configs
		prepare_paths
		launch_workload
	done
done