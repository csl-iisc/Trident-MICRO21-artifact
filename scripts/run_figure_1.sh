#!/bin/bash

BENCHMARKS="xsbench gups svm redis btree graph500 memcached canneal pr cc bc cg"
CONFIGS="4KB 2MBTHP 2MBHUGE" #1GBHUGE
# For 1GBHUGE, boot kernel with command-line parameter "default_hugepagesz=1G"
# and uncomment the following line
#CONFIGS="1GBHUGE"

SCRIPTS=$(dirname `readlink -f "$0"`)
ROOT="$(dirname "$SCRIPTS")"
source $SCRIPTS/common.sh
source $SCRIPTS/configs.sh

for CONFIG in $CONFIGS; do
	for BENCHMARK in $BENCHMARKS; do
		cleanup_system_configs
		setup_4kb_configs
		drop_caches
		prepare_args
		prepare_system_configs
		prepare_paths
		launch_workload
	done
done
