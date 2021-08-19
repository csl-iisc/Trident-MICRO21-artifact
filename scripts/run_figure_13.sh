#!/bin/bash

BENCHMARKS="xsbench gups svm redis btree graph500 memcached canneal"
CONFIGS="2MBTHP-2MBTHP-F TRIDENT-TRIDENT-F TRIDENTPV-TRIDENTPV-F"

SCRIPTS=$(dirname `readlink -f "$0"`)
ROOT="$(dirname "$SCRIPTS")"
source $SCRIPTS/common.sh
source $SCRIPTS/configs.sh

for CONFIG in $CONFIGS; do
	cleanup_system_configs
	setup_4kb_configs
	drop_caches
	prepare_system_configs
	prepare_kvm_vm
	SRC=$SCRIPTS/run_guest.sh
	for BENCHMARK in $BENCHMARKS; do
		ssh $GUESTUSER@$GUESTIP "\"$SRC\" \"$BENCHMARK\" \"$CONFIG\""
	done
done
