#!/bin/bash

BENCHMARKS="xsbench gups svm redis btree graph500 memcached canneal"
#CONFIGS="2MBTHP-2MBTHP HAWKEYE-HAWKEYE TRIDENT-TRIDENT"
# -- Better to re-use 2MBTHP-2MBTHP from Figure-2
CONFIGS="TRIDENT-TRIDENT"
# -- For HAWKEYE-HAWKEYE, boot system with HawkEye and uncomment the following line
#CONFIGS="HAWKEYE-HAWKEYE"

SCRIPTS=$(dirname `readlink -f "$0"`)
ROOT="$(dirname "$SCRIPTS")"
source $SCRIPTS/common.sh
source $SCRIPTS/configs.sh

for BENCHMARK in $BENCHMARKS; do
	for CONFIG in $CONFIGS; do
		cleanup_system_configs
		setup_4kb_configs
		drop_caches
		prepare_system_configs
		prepare_kvm_vm
		SRC=$SCRIPTS/run_guest.sh
		ssh $GUESTUSER@$GUESTIP "\"$SRC\" \"$BENCHMARK\" \"$CONFIG\""
	done
done
