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
source $SCRIPTS/configs.sh

cleanup_system_configs
setup_4kb_configs # --- setup everything with normal system config
fragment_memory
prepare_args
prepare_system_configs
prepare_paths
launch_workload
cleanup_system_configs
