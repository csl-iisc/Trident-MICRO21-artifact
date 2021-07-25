#!/bin/bash

BENCHMARKS="xsbench gups svm redis btree graph500 memcached canneal"
# -- To execute with HAWKEYE, boot your system with HAWKEYE kernel image
CONFIGS="2MBTHPF HAWKEYEF TRIDENTF"

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
