#!/bin/bash

BENCHMARKS="xsbench gups svm redis btree graph500 memcached canneal"
CONFIGS="2MBTHP2MBTHP HAWKEYEHAWKEYE TRIDENTTRIDENT"

SCRIPTS=$(dirname `readlink -f "$0"`)
ROOT="$(dirname "$SCRIPTS")"
source $SCRIPTS/common.sh
source $SCRIPTS/configs.sh

for BENCHMARK in $BENCHMARKS; do
	for CONFIG in $CONFIGS; do
		cleanup_system_configs
		setup_4KB_configs
		fragment_memory
		prepare_system_configs
		prepare_kvm_vm
		SRC=$SCRIPTS/run_guest.sh
		ssh $GUESTUSER@$GUESTIP "\"$SRC\" \"$BENCHMARK\" \"$CONFIG\""
	done
done
