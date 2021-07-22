#!/usr/bin/python3

import xml.etree.ElementTree as ET
import os
import sys
import multiprocessing
import subprocess
import psutil

KERNEL_MITOSIS='/boot/vmlinuz-5.4.0-80-generic'
INITRD_MITOSIS='/boot/initrd.img-5.4.0-80-generic'
CMDLINE_MITOSIS='console=ttyS0 root=/dev/sda1'

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

nr_cpus = multiprocessing.cpu_count()
nr_sockets =  int(subprocess.check_output('cat /proc/cpuinfo | grep "physical id" \
                | sort -u | wc -l', shell=True))
# --- XML helper
def remove_tag(parent, child):
    for element in list(parent):
        if element.tag == child:
            parent.remove(element)

# --- XML helper
def new_element(parent, tag, text):
    attrib = {}
    element = parent.makeelement(tag, attrib)
    parent.append(element)
    element.text = text
    return element


# return the number of CPUs from a single socket
def get_vcpu_count(config):
	return int(nr_cpus/nr_sockets)

# return memory size of a single socket
def get_memory_size(config):
    mem = int(psutil.virtual_memory().total)/1024 # --- converted to KB
    return int((mem * 0.80) / nr_sockets) # --- some fraction of total memory


# -- host physical bits need to be set for VMs greate than 1TB.
# Add them anyway for simplicity.
def test_and_set_hpb(tag):
    machine = tag.get('machine')
    if '-hpb' not in machine:
        tag.set('machine', machine+'-hpb')


# Rewrite to boot with mitosis kernel image
def rewrite_os(tag):
    #new = new_element(tag_os, 'kernel', '/boot/vmlinuz-4.17.0-mitosis+')
    addKernel = True
    addInitrd = True
    addCmdline = True
    for child in tag:
        if child.tag == 'kernel':
            child.text = KERNEL_MITOSIS
            addKernel = False
        if child.tag == 'initrd':
            child.text = INITRD_MITOSIS
            addInitrd = False
        if child.tag == 'cmdline':
            child.text = CMDLINE_MITOSIS
            addCmdline = False
        #if child.tag == 'type':
        #    test_and_set_hpb(child)

    if addKernel:
        newtag = new_element(tag, 'kernel', KERNEL_MITOSIS)
    if addInitrd:
        newtag = new_element(tag, 'initrd', INITRD_MITOSIS)
    if addCmdline:
        newtag = new_element(tag, 'cmdline', CMDLINE_MITOSIS)

# Bind vCPUs 1:1: to pCPUs
def add_vcpu_numa_tune(config, main, child):
    nr_cpus = int(child.text)
    pos = list(main).index(child)
    remove_tag(main, 'cputune')
    new = ET.Element('cputune')
    main.insert(pos + 1, new)
    cpus = [i for i in range(nr_cpus)]
    out = subprocess.check_output('numactl -H | grep "node 0 cpus" | cut -d " " -f4-', shell  = True)
    out = str(out, 'utf-8')
    cpus = out.split()
    for i in range(nr_cpus):
        newtag = ET.SubElement(new, 'vcpupin')
        newtag.set('cpuset', str(cpus[i]))
        newtag.set('vcpu', str(i))

    remove_tag(main, 'numatune')
    return

def add_memory_backing(config, main, child):
    remove_tag(main, 'memoryBacking')
    if config == '4KB':
        return
    pos = list(main).index(child)
    mem_backing = ET.Element('memoryBacking')
    main.insert(pos + 1, mem_backing)
    hugepages = ET.SubElement(mem_backing, 'hugepages')
    page = ET.SubElement(hugepages, 'page')
    if config == '2MBHUGE':
        page.set('size', '2048')
        page.set('unit', 'KiB')
    if config == '1GBHUGE':
        page.set('size', '1048576')
        page.set('unit', 'KiB')


# -- the following tags are important
# 1. os: update to booth VM with mitosis kernel
# 2. vcpu: number of vcpus for the VM
# 3. memory: amount of memory for the VM -- in KiB
# 4. vcputune: add after the vcpu tag, bind with a 1:1 mapping
# 5. numa: add inside cpu tag to mirror host NUMA topology inside guest
def rewrite_config(config):
    vmconfigs = os.path.join(root, 'vmconfigs')
    src = os.path.join(vmconfigs, config + '.xml')
    tree = ET.parse(src)
    main = tree.getroot()
    for child in main:
        if child.tag == 'os':
            rewrite_os(child)
        if child.tag == 'vcpu':
            child.text = str(get_vcpu_count(config))
            add_vcpu_numa_tune(config, main, child)
        if child.tag == 'memory':
            add_memory_backing(config, main, child)

    tree.write(src)

def dump_vm_config_template(vm, configs):
    print('dumping template XML from %s\'s current config...' %vm)
    cmd = 'virsh dumpxml %s' %vm
    dst = os.path.join(root, 'vmconfigs/')
    if not os.path.exists(dst):
        os.makedirs(dst)
    dst = os.path.join(dst, 'template.xml')
    cmd += '> %s' %dst
    os.system(cmd)
    # -- copy into three files
    src = dst
    for config in configs:
        dst = os.path.join(root, 'vmconfigs')
        dst = os.path.join(dst, config + '.xml')
        cmd = 'cp %s %s '%(src, dst)
        os.system(cmd)
        #print(cmd)

if __name__ == '__main__':
    parent_vm = 'trident'
    if len(sys.argv) == 2:
        parent_vm = sys.argv[1]

    configs = ['4KB', '2MBHUGE', '1GBHUGE']
    dump_vm_config_template(parent_vm, configs)
    for config in configs:
        print('re-writing: ' + config+'.xml')
        rewrite_config(config)

    # --- prettify XML files
    for config in configs:
        vmconfigs = os.path.join(root, 'vmconfigs')
        src = os.path.join(vmconfigs, config + '.xml')
        cmd = 'xmllint --format %s' %src
        tmp = 'tmp.xml'
        cmd += ' > %s' %tmp
        os.system(cmd)
        os.rename(tmp, src)
