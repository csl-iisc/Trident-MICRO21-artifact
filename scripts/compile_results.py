#!/usr/bin/python3

import sys
import os
import csv
import shutil

benchmarks = dict()
curr_bench = ""
curr_config = ""
summary = []
avg_summary = []
benchmarks = []
global verbose

# --- all workload configurations
configs = ['4KB', '2MBTHP', '2MBHUGE', '1GBHUGE', 'TRIDENT', 'TRIDENT-1G', 'TRIDENT-NC', 'HAWKEYE', '2MBTHPF', 'TIDENTF', 'TRIDENT-1GF', 'TRIDENT-NCF', 'HAWKEYEF', '4KB4KB', '2MBTHP2MBTHP', 'TRIDENTTRIDENT', 'HAWKEYEHAWKEYE', '2MBTHPF2MBTHPF', 'TRIDENTFTRIDENTF', 'TRIDENTFPVTRIDENTFPV']
pretty_configs = ['4KB', '2MB-THP', '2MB-HUGE', '1GB-HUGE', 'Trident', 'Trident-1G', 'Trident-NC', 'HawkEye', '2MB-THP', 'Trident', 'Trident-1G', 'Trident-NC', 'HawkEye', '4KB-4KB', '2MBTHP-2MBTHP', 'Trident-Trident', 'Hawkeye-HawkEye', '2MB-2MB', 'Trident-Trident', 'TridentPV-TridentPV']
# --- all workloads
workloads = ['xsbench', 'gups', 'svm', 'redis', 'btree', 'graph500', 'memcached', 'canneal', 'pr', 'cc', 'bc', 'cg']

main_workloads = ['xsbench', 'gups', 'svm', 'redis', 'btree', 'graph500', 'memcached', 'canneal']
fig1_configs = ['4KB', '2MBTHP', '2MBHUGE', '1GBHUGE']
fig2_configs = ['4KB4KB', '2MBTHP2MBTHP', '1GBHUGE1GBHUGE']
fig9_configs = ['2MBTHP', 'HAWKEYE', 'TRIDENT']
fig10_configs = fig9_configs
fig11a_configs = ['2MBTHP', 'TRIDENT-1G', 'TRIDENT-NC', 'TRIDENT'] 
fig11b_configs = ['2MBTHPF', 'TRIDENT-1GF', 'TRIDENT-NCF', 'TRIDENTF'] 
fig12_configs = ['2MBTHP2MBTHP', 'HAWKEYEHAWKEYE', 'TRIDENTTRIDENT'] 

def get_time_from_log(line):
    exec_time = int(line[line.find(":")+2:])
    return exec_time

def open_file(src, op):
    try:
        fd = open(src, op)
        if fd is None:
            raise ("Failed")
        return fd
    except:
        if verbose:
            #print("Unable to open %s in %s mode" %(src, op))
            pass
        return None

def print_workload_config(log):
    global curr_bench, curr_config

    for bench in workloads:
        if bench in log:
            curr_bench = bench
            break

    config = ""
    for tmp in configs:
            search_name = "-" + tmp + "-"
            if search_name in log:
                config =tmp
                break

    curr_config = config
    benchmarks.append(curr_bench)

def process_perf_log(path):
    fd = open_file(path, "r")
    if fd is None:
        print ('error opening log file')
        sys.exit(1)

    exec_time = cycles = loads = stores = -1
    for line in fd:
        if 'Execution Time (seconds)' in line:
            exec_time = get_time_from_log(line)
        if ',cycles' in line:
            cycles = float(line.split(',')[0])
        if ',dtlb_load_misses.walk_active' in line:
            loads = float(line.split(',')[0])
        if ',dtlb_store_misses.walk_active' in line:
            stores = float(line.split(',')[0])

    fd.close()
    # --- log may be from an incomplete run and if so, ignore
    if exec_time == -1:
        return

    output = {}
    output['bench'] = curr_bench
    output['config'] = curr_config
    output['time'] = exec_time
    output['pwc'] = round((((loads + stores) * 100)/cycles), 2)
    print(output)
    summary.append(output)
 
def traverse_benchmark(path):
    # --- process THP and NON-THP configs separately
    for root,dir,files in os.walk(path):
        for filename in files:
            log = os.path.join(root, filename)
            print_workload_config(log)
            process_perf_log(log)

def pretty(name):
    if name in configs:
        index = configs.index(name)
        return pretty_configs[index]
    return name

def dump_workload_config_average(output, bench, config, fd, fd2, absolute):
    time = count = pwc = 0
    for result in output:
        if result['bench'] == bench and result['config'] == config:
            time += result['time']
            pwc += result['pwc']
            line = '%s\t%s\t%d\t%0.2f\n' % (pretty(bench), pretty(config), result['time'], result['pwc'])
            fd2.write(line)
            count += 1

    if count == 0:
        return

    if absolute:
            time = int (time / count)
            pwc = float (pwc / count)
            line = '%s\t%s\t%d\t%0.2f\n' % (pretty(bench), pretty(config), time, pwc)
            fd.write(line)
            output = {}
            output['bench'] = bench
            output['config'] = config
            output['time'] = time
            output['pwc'] = pwc
            avg_summary.append(output)

def process_all_runs(fd, fd2, output, absolute):
    global benchmarks, configs, curr_bench
    benchmarks = list(dict.fromkeys(benchmarks))

    if absolute:
        fd.write('Workload\tConfiguration\tTime\tPWC\n')
        fd2.write('Workload\tConfiguration\tTime\tPWC\n')
    else:
        fd.write('Workload\tConfiguration\tTime\n')
    for bench in workloads:
        curr_bench = bench
        for config in configs:
            dump_workload_config_average(output, bench, config, fd, fd2, absolute)

def gen_csv_common(dst, benchs, confs, baseline, metric):
    out_fd = open(dst, mode = 'w')
    writer = csv.writer(out_fd, delimiter='\t', quoting=csv.QUOTE_MINIMAL)
    denominator = 1000000.0

    for workload in benchs:
        for exp in avg_summary:
            if exp['bench'] == workload and exp['config'] == baseline:
                denominator = exp[metric]

        for config in confs:
            for exp in avg_summary:
                if exp['bench'] == workload and exp['config'] == config:
                    writer.writerow([workload, pretty_configs[configs.index(config)], round(exp[metric] / denominator, 2)])


def gen_fig1_csv(root):
    out_csv = os.path.join(root, ('report/figure-1a.csv'))
    gen_csv_common(out_csv, workloads, fig1_configs, '4KB', 'time')
    out_csv = os.path.join(root, ('report/figure-1b.csv'))
    gen_csv_common(out_csv, workloads, fig1_configs, '4KB', 'pwc')

def gen_fig2_csv(root):
    out_csv = os.path.join(root, ('report/figure-2a.csv'))
    gen_csv_common(out_csv, workloads, fig2_configs, '4KB-4KB', 'time')
    out_csv = os.path.join(root, ('report/figure-2b.csv'))
    gen_csv_common(out_csv, workloads, fig2_configs, '4KB-4KB', 'pwc')

def gen_fig9_csv(root):
    out_csv = os.path.join(root, ('report/figure-9a.csv'))
    gen_csv_common(out_csv, main_workloads, fig9_configs, '2MBTHP', 'time')
    out_csv = os.path.join(root, ('report/figure-9b.csv'))
    gen_csv_common(out_csv, main_workloads, fig9_configs, '2MBTHP', 'pwc')

def gen_fig10_csv(root):
    out_csv = os.path.join(root, ('report/figure-10a.csv'))
    gen_csv_common(out_csv, main_workloads, fig10_configs, '2MBTHPF', 'time')
    out_csv = os.path.join(root, ('report/figure-10b.csv'))
    gen_csv_common(out_csv, main_workloads, fig10_configs, '2MBTHPF', 'pwc')

def gen_fig11_csv(root):
    out_csv = os.path.join(root, ('report/figure-11a.csv'))
    gen_csv_common(out_csv, main_workloads, fig11a_configs, '2MBTHP', 'time')
    out_csv = os.path.join(root, ('report/figure-11b.csv'))
    gen_csv_common(out_csv, main_workloads, fig11b_configs, '2MBTHPF', 'time')

def gen_fig12_csv(root):
    out_csv = os.path.join(root, ('report/figure-12.csv'))
    gen_csv_common(out_csv, main_workloads, fig12_configs, '2MBTHP2MBTHP', 'time')

def gen_report(root):
    gen_fig1_csv(root)
    gen_fig2_csv(root)
    gen_fig9_csv(root)
    gen_fig10_csv(root)
    gen_fig11_csv(root)
    gen_fig12_csv(root)

if __name__=="__main__":
    summary = []
    avg_summary = []
    root = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    datadir = os.path.join(root, "evaluation/")
    out_dir = os.path.join(root, "report/")
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    for benchmark in workloads:
        path = os.path.join(datadir, benchmark)
        traverse_benchmark(path)

    avg_src = os.path.join(out_dir, "avg.csv")
    all_src = os.path.join(out_dir, "all.csv")


    #print(avg_src)
    #print(all_src)
    fd_avg = open_file(avg_src, "w")
    fd_all = open_file(all_src, "w")
    if fd_avg is None or fd_all is None:
        print("ERROR creating output files")
        sys.exit()

    # --- process normalized data
    process_all_runs(fd_avg, fd_all, summary, True)
    fd_avg.close()
    fd_all.close()

    gen_report(root)

