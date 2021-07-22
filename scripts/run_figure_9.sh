#!/bin/bash

BENCHMARKS="xsbench gups svm redis btree graph500 memcached canneal pr cc bc cg"
# To execute 1GBHUGE or 2MBHUGE configurations, boot your kernel with command-line parameter
# "default_hugepagesz=1G or default_hugepagesz=2M"
CONFIGS="2MBTHP HAWKEYE TRIDENT"  # --- re-use 2MBTHP from Figure-1
CONFIGS="HAWKEYE TRIDENT"

BENCHMARKS="gups"

SCRIPTS=$(dirname `readlink -f "$0"`)
ROOT="$(dirname "$SCRIPTS")"
source $SCRIPTS/common.sh

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
