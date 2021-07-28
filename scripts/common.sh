#!/bin/bash

# --- set of common functions and variables used across all experiments
MEMCACHED_ARGS=" "
CANNEAL_ARGS=" 1 150000 2000 $ROOT/datasets/canneal_small 7500 "
XSBENCH_ARGS=" -s XL -t 24 -l 800000000"
GRAPH500_ARGS=" -s 26 -e 30"
SVM_ARGS="-- -s 6 -n 36 $ROOT/datasets/kdd12"
GUPS_ARGS=" 32 5000000 1024"
GAPBS_ARGS=" -g 29 -n 20 -i 20"

# always run on socket-0
DATA_NODE=0
CPU_NODE=0

# number of hugetlb pages
HUGETLB_2MB_PAGES=80000
HUGETLB_1GB_PAGES=160

drop_caches()
{
	echo "Dropping caches for config: $CONFIG"
	echo 3 |  sudo tee /proc/sys/vm/drop_caches > /dev/null
}

fragment_memory()
{
	if [[ $CONFIG = *F* ]]; then
                echo "Fragmenting memory for config: $CONFIG"
                if [ ! -e $FRAG_FILE_1 ] || [ ! -e $FRAG_FILE_2 ]; then
                        echo "***FRAGMENTATION FILES MISSING***"
                        exit
                fi
                echo -e "Reading first file"
                $ROOT/bin/numactl -c $CPU_NODE -m $DATA_NODE cat $FRAG_FILE_1 > /dev/null &
                PID_1=$!
                echo -e "Reading second file"
                $ROOT/bin/numactl -c $CPU_NODE -m $DATA_NODE cat $FRAG_FILE_2 > /dev/null &
                PID_2=$!
                echo "Waiting for files to load in memory: PID1: $PID_1 PID2: $PID_2"
                wait $PID_1
                wait $PID_2
                echo -e "Launching client to fragment memory...."
                # --- Run for 10 minutes
                $ROOT/bin/numactl -c $CPU_NODE -m $DATA_NODE python $SCRIPTS/fragment.py $FRAG_FILE_1 $FRAG_FILE_2 600 36 > /dev/null
        else
		drop_caches
        fi
}

prepare_paths()
{
        BENCHPATH=$ROOT"/bin/$BENCHMARK"
        INTERFERENCEPATH=$ROOT"/bin/bench_stream"
        PERF=$ROOT"/bin/perf"
        NUMACTL=$ROOT"/bin/numactl"
        if [ ! -e $BENCHPATH ]; then
            echo "Benchmark binary is missing: $BENCHPATH"
            exit
        fi
        if [ ! -e $PERF ]; then
            echo "Perf binary is missing: $PERF "
            exit
        fi
        if [ ! -e $NUMACTL ]; then
            echo "numactl is missing: $NUMACTL"
            exit
        fi
        # where to put the output file (based on CONFIG)
        DATADIR=$ROOT"/evaluation/$BENCHMARK"
        RUNDIR=$DATADIR/$(hostname)-$BENCHMARK-$CONFIG-$(date +"%Y%m%d-%H%M%S")
        mkdir -p $RUNDIR
        if [ $? -ne 0 ]; then
                echo "Error creating output directory: $RUNDIR"
        fi
        OUTFILE=$RUNDIR/perflog-$BENCHMARK-$(hostname)-$CONFIG.dat
}

prepare_args()
{
        BENCH_ARGS=""
        if [ $BENCHMARK = "canneal" ]; then
                BENCH_ARGS=$CANNEAL_ARGS
        elif [ $BENCHMARK = "gups" ]; then
                BENCH_ARGS=$GUPS_ARGS 
        elif [ $BENCHMARK = "memcached" ]; then
                BENCH_ARGS=$MEMCACHED_ARGS 
        elif [ $BENCHMARK = "xsbench" ]; then
                BENCH_ARGS=$XSBENCH_ARGS
        elif [ $BENCHMARK = "graph500" ]; then
                BENCH_ARGS=$GRAPH500_ARGS
        elif [ $BENCHMARK = "svm" ]; then
                BENCH_ARGS=$SVM_ARGS
        elif [ $BENCHMARK = "pr" ] || [ $BENCHMARK = "cc" ] || [ $BENCHMARK = "bc" ]; then
                BENCH_ARGS=$GAPBS_ARGS
        fi
}

setup_trident_configs()
{
        THP="always"
        echo $THP |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null 2>&1
        echo 1 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/defrag > /dev/null 2>&1
        echo 1 |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled_pmd > /dev/null 2>&1
        echo 1 |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled_pud > /dev/null 2>&1
        echo 1 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/khugepaged_collapse_pmd > /dev/null 2>&1
        echo 1 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/khugepaged_collapse_pud > /dev/null 2>&1
        echo 1 |  sudo tee /proc/sys/vm/compaction_smart > /dev/null 2>&1
        echo 5 |  sudo tee /proc/sys/vm/smart_compaction_retries 2>&1
        echo 2097152 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/pages_to_scan > /dev/null 2>&1
	echo 0 | sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/collapse_via_hypercall > /dev/null 2>&1
}

setup_trident_nosmart_configs()
{
	setup_trident_configs
        echo 0 |  sudo tee /proc/sys/vm/compaction_smart > /dev/null 2>&1
        echo 1 |  sudo tee /proc/sys/vm/smart_compaction_retries 2>&1
}

setup_trident_1gbonly_configs()
{
	setup_trident_configs
        echo 0 |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled_pmd > /dev/null 2>&1
        echo 0 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/khugepaged_collapse_pmd > /dev/null 2>&1
}

setup_tridentpv_configs()
{
	setup_trident_configs
	echo 1 | sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/collapse_via_hypercall > /dev/null 2>&1
}

setup_2mbthp_configs()
{
        THP="always"
        echo $THP |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null 2>&1 
        echo never |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled_1gb > /dev/null 2>&1
        echo 1 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/defrag > /dev/null 2>&1
        echo 1 |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled_pmd > /dev/null 2>&1
        echo 0 |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled_pud > /dev/null 2>&1
        echo 1 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/khugepaged_collapse_pmd > /dev/null 2>&1
        echo 0 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/khugepaged_collapse_pud > /dev/null 2>&1
        echo 0 |  sudo tee /proc/sys/vm/compaction_smart > /dev/null 2>&1
        #echo 5 |  sudo tee /proc/sys/vm/smart_compaction_retries
        echo 4096 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/pages_to_scan > /dev/null 2>&1
}

setup_4kb_configs()
{
        THP="never"
        echo $THP |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null 2>&1
        echo $THP |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled_1gb > /dev/null 2>&1
        echo 0 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/defrag > /dev/null 2>&1
        echo 0 |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled_pmd > /dev/null 2>&1
        echo 0 |  sudo tee /sys/kernel/mm/transparent_hugepage/enabled_pud > /dev/null 2>&1
        echo 0 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/khugepaged_collapse_pmd > /dev/null 2>&1
        echo 0 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/khugepaged_collapse_pud > /dev/null 2>&1
        echo 0 |  sudo tee /proc/sys/vm/compaction_smart > /dev/null 2>&1
        #echo 5 |  sudo tee /proc/sys/vm/smart_compaction_retries
        echo 4096 |  sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/pages_to_scan > /dev/null 2>&1
}

PREFIX='/sys/devices/system/node/node0/hugepages/'
prepare_system_configs()
{
        CONFIG=$1
        # --- reserve/drain HUGETLB Pool
	if [ $CONFIG = "2MBHUGE" ]; then
		echo $HUGETLB_2MB_PAGES | sudo tee $PREFIX/hugepages-2048kB/nr_hugepages
	elif [ $CONFIG = "1GBHUGE" ]; then
		echo $HUGETLB_1GB_PAGES | sudo tee $PREFIX/hugepages-1048576kB/nr_hugepages
	fi
	# reserve hugetlb pages
        $ROOT/bin/numactl -m $DATA_NODE echo $NR_HUGETLB_PAGES |
		sudo tee /proc/sys/vm/nr_hugepages_mempolicy > /dev/null 2>&1
        if [[ $CONFIG = *2MB* ]]; then
                setup_2mbthp_configs
        elif [[ $CONFIG = *HAWKEYE* ]]; then
                setup_2mbthp_configs
        elif [[ $CONFIG = *1GBHUGE* ]]; then
                setup_2mbthp_configs #leave 2MB THP on even when 1GB HUGETLB is enabled
        elif [ $CONFIG = "TRIDENT" ]; then
                setup_trident_configs
        elif [[ $CONFIG = *TRIDENT-NC* ]]; then # TRIDENT with no smart compaction
                setup_trident_nosmart_configs
        elif [[ $CONFIG = *TRIDENT-1G* ]]; then # TRIDENT with 1GB pages only
                setup_trident_1gbonly_configs
        elif [[ $CONFIG = *TRIDENT*PV* ]]; then # Paravirtualized TRIDENT
		setup_tridentpv_configs
        else
                setup_4kb_configs
        fi
        echo "Configuration: $CONFIG completed."
}

cleanup_system_configs()
{
        # --- Drain HUGETLB Pool
	echo 0 | sudo tee $PREFIX/hugepages-2048kB/nr_hugepages
	echo 0 | sudo tee $PREFIX/hugepages-1048576kB/nr_hugepages
}

launch_workload()
{
        # --- clean up exisiting state/processes
        rm /tmp/alloctest-bench.ready &>/dev/null
        rm /tmp/alloctest-bench.done &> /dev/null
	echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid > /dev/null
        CMD_PREFIX=$NUMACTL
        if [ $CONFIG = "2MBHUGE" ] || [ $CONFIG = "1GBHUGE" ]; then
                #CMD_PREFIX=" LD_PRELOAD=libhugetlbfs.so HUGETLB_MORECORE=2M $NUMACTL"
                CMD_PREFIX=" hugectl --heap $NUMACTL"
        fi
        CMD_PREFIX+=" -m $DATA_NODE -c $CPU_NODE "
        LAUNCH_CMD="$CMD_PREFIX $BENCHPATH $BENCH_ARGS"
        REDIRECT="/dev/null"
        echo $LAUNCH_CMD
        touch $OUTFILE
        cat /proc/vmstat | egrep 'migrate|th' >> $RUNDIR/vmstat
        sleep 1
        $LAUNCH_CMD > $REDIRECT 2>&1 &
        #$LAUNCH_CMD &
        BENCHMARK_PID=$!
        if [ $CONFIG = "HAWKEYE" ]; then
                sleep 1
                $ROOT/bin/notify_hawkeye -p $BENCHMARK_PID > /dev/null 2>&1
                echo "Added PID: $BENCHMARK_PID to HawkEye Scan List..."        
        fi
        SECONDS=0
        echo -e "\e[0mWaiting for benchmark: $BENCHMARK_PID to be ready"
        while [ ! -f /tmp/alloctest-bench.ready ]; do
                sleep 0.1
        done
        INIT_DURATION=$SECONDS
        if [ $CONFIG = "2MBR" ] || [ $CONFIG = "1GBTR" ]; then
                echo "Launching Interference on NODE: 0 ..."
                $ROOT/bin/numactl -c 0 -m 0 $INTERFERENCEPATH > /dev/null 2>&1 &
        fi
        echo -e "Initialization Time (seconds): $INIT_DURATION"
        SECONDS=0
        $PERF stat -x, -o $OUTFILE --append -e $PERF_EVENTS -p $BENCHMARK_PID &
        PERF_PID=$!
        echo -e "\e[0mWaiting for benchmark to be done"
        while [ ! -f /tmp/alloctest-bench.done ]; do
                sleep 0.1
        done
        DURATION=$SECONDS
        echo "****success****" >> $OUTFILE
        echo -e "Execution Time (seconds): $DURATION" >> $OUTFILE
        echo -e "Execution Time (seconds): $DURATION"
        echo -e "Initialization Time (seconds): $INIT_DURATION\n" >> $OUTFILE
        kill -INT $PERF_PID &> /dev/null
        wait $PERF_PID
        cat /proc/vmstat | egrep 'migrate|th' >> $RUNDIR/vmstat
        wait $BENCHMARK_PID 2>/dev/null
}

copy_vm_config()
{
	VMXML=$ROOT/vmconfigs/4KB.xml # -- same XML works for 2MBTHP and HAWKEYE as well
	if [ $CONFIG = "2MBHUGE" ]; then
		VMXML=$ROOT/vmconfigs/2MBHUGE.xml
	elif [ $CONFIG = "1GBHUGE" ]; then
		VMXML=$ROOT/vmconfigs/1GBHUGE.xml
	fi
	sudo service libvirtd stop
	sudo cp $VMXML /etc/libvirt/qemu/$VMIMAGE.xml
	sudo service libvirtd start
	echo "VM configuration updated..."
}

shutdown_kvm_vm()
{
	echo "Trying normal shutdown..."
	ssh $GUESTUSER@$GUESTIP 'sudo shutdown now' > /dev/null
	sleep 5
	virsh destroy $VMIMAGE > /dev/null 2>&1
	sleep 1
	echo "VM stopped..."
}

boot_kvm_vm()
{
	virsh start $VMIMAGE > /dev/null
	if [ $? -ne 0 ]; then
		echo "error starting vm. Exiting."
		exit
	fi
	echo "VM started..."
	sleep 45
}

prepare_kvm_vm()
{
	shutdown_kvm_vm
	copy_vm_config
	boot_kvm_vm
}
