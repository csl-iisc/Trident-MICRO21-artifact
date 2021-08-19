#!/bin.bash

VMIMAGE=trident

GUESTUSER=micro21ae
GUESTIP=192.168.123.149

PERF_EVENTS='cycles,dtlb_load_misses.walk_active,dtlb_store_misses.walk_active'
#PERF_EVENTS='cycles,instructions'

PROFILE_PERF_EVENTS="yes" #no

FRAG_FILE_1=$ROOT/datasets/fragmentation/file-1
FRAG_FILE_2=$ROOT/datasets/fragmentation/file-2

# number of hugetlb pages
HUGETLB_2MB_PAGES=70000
HUGETLB_1GB_PAGES=140

# number of hugetlb pages
VM_HUGETLB_2MB_PAGES=80000
VM_HUGETLB_1GB_PAGES=160
