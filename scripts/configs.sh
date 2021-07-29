#!/bin.bash

VMIMAGE=trident

HOSTUSER=ashish
HOSTIP=10.192.13.20

GUESTUSER=ashish
GUESTIP=192.168.122.188

PERF_EVENTS='cycles,dtlb_load_misses.walk_active,dtlb_store_misses.walk_active'
#PERF_EVENTS='cycles,instructions'

FRAG_FILE_1=$ROOT/datasets/fragmentation/file-1
FRAG_FILE_2=$ROOT/datasets/fragmentation/file-2
