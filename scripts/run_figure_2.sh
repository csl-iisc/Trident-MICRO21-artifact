#!/bin/bash

BENCHMARKS="xsbench gups svm redis btree graph500 memcached canneal pr cc bc cg"
CONFIGS="4KB-4KB 2MBHUGE-2MBHUGE" #1GBHUGE-1GBHUGE
# For 1GBHUGE-1GBHUGE, boot host kernel with command-line parameter "default_hugepagesz=1G"
# and uncomment the following line
#CONFIGS="1GBHUGE-1GBHUGE"

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
