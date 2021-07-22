#!/bin/bash

BENCHMARK=$1
CONFIG=$2
if [ $# -ne 2 ]; then
	echo "Supply benchmark name and config."
	exit
fi

SCRIPTS=$(dirname `readlink -f "$0"`)
ROOT="$(dirname "$SCRIPTS")"
source $SCRIPTS/common.sh

cleanup_system_configs
setup_4KB_configs # --- setup everything with normal system config
fragment_memory $CONFIG
prepare_args $CONFIG
prepare_system_configs $CONFIG
prepare_paths_virtual $BENCHMARK $CONFIG
launch_workload
cleanup_system_configs
