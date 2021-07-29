Trident MICRO'21 Artifact Evaluation
=====================================

This repository contains scripts and other supplementary material
for the MICRO'21 artifact evaluation of the paper **Trident: Harnessing
Micro-architectural Resources for All Page Sizes in x86 Processors **.

Authors
-------
 
 * Venkat Sai Ram (Indian Institute of Science)
 * Ashish Panwar (Indian Institute of Science)
 * Arkaprava Basu (Indian Institute of Science)


Directory Structure
-------------------

 * `bin/` contains all the binaries
 * `datasets/` contains the datasets required for the binaries
 * `scripts/` contains scripts to run the experiments
 * `evaluation/` experimental logs are redirected here
 * `vmconfigs/` stores libvirt's XML configuration files
 * `report/` will contain process logs in CSV format


Hardware Dependencies
---------------------

Some of the workingset sizes of the workloads are hardcoded in the binaries.
To run them, you need to have a machine with at least 128GB memory on a single
socket.


Software Dependencies
---------------------

The scripts and binaries are tested on Ubuntu 18.04 LTS. Other 
Linux distributions may work, but are not tested.

In addition to the packages shipped with Ubuntu 18.04 LTS the following 
packets are required:

```
$ sudo apt install build-essential bison bc \
		libncurses-dev flex libssl-dev automake \
		libelf-dev libnuma-dev python3 git \
		wget libncurses5-dev libevent-dev \
		libreadline-dev libtool autoconf \
		qemu-kvm libvirt-bin bridge-utils \
		virtinst virt-manager hugepages \
		libgfortran3 libhugetlbfs-dev

```                       

Pre-Compiled Binaries
---------------------

If you only plan to use the pre-compiled binaries, install Trident kernel headers and image, and
boot your target machine with it before running any experiments.

```
$ dpkg -i bin/linux-headers-4.17.3-trident+_4.17.3-trident+-3_amd64.deb
$ dpkg -i bin/linux-image-4.17.3-trident+_4.17.3-trident+-3_amd64.deb
```

Obtaining Source Code and Compile
---------------------------------

The source of Trident and HawkEye [ASPLOS'19] kernels are available on GitHub and included as
public submodules. To obtain the source code, initialize the git submodules:

```
$ cd Trident-MICRO21-artifact
$ git submodule init
$ git submodule update
```
To compile Trident, do:

```
$ cd Trident-MICRO21-artifact/sources/Trident; git checkout trident
$ cp config .config; make oldconfig
$ make -j; make install -j; update-grub;
```

To compile HawkEye, do:

```
$ cd Trident-MICRO21-artifact/sources/HawkEye; git checkout hawkeye
$ cp config .config; make oldconfig
$ make -j; make install -j; update-grub;
```

Install and Create Virtual Machine Configurations
-------------------------------------------------

Install a virtual machine using command line (choose ssh-server when prompted for package installation):

```
$ virt-install --name trident --ram 8192 --disk path=/home/ashish/vms/trident.qcow2,size=60 --vcpus 8 --os-type linux --os-variant generic --network bridge=virbr0 --graphics none --console pty,target_type=serial --location 'http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' --extra-args 'console=ttyS0,115200n8 serial'
```
Once installed, use the following script to prepare VM configuration files:
```
$ Trident-MICRO21-artifact/scripts/gen_vmconfigs.py trident

```
If it works well, skip the rest of this subsection. Otherwise you may have to manually create VM configurations following the instructions provided below.

Copy the default XML configuration file in three files under `Trident-MICRO21-artifact/vmconfigs/`:
```
$ virsh dumpxml trident > Trident-MICRO21-artifact/vmconfigs/4KB.xml
$ virsh dumpxml trident > Trident-MICRO21-artifact/vmconfigs/2MBHUGE.xml
$ virsh dumpxml trident > Trident-MICRO21-artifact/vmconfigs/1GBHUGE.xml
```

Now, update each configuration file to configure the number of vCPUs, memory and NUMA-topology as follows:
1. **memory size** : All memory available on socket-0
2. **vCPUs** : All CPU threads of socket-0

For all these configurations, the following tags are important:
```
1. <vcpu> </vcpu> -- to update the number of CPUs to be allocated to the VM
2. <memory> </memory> -- to update the amount of memory to be allocated to the VM
3. <cputune> <cputune> -- to bind vCPUs to pCPUs
```

The guest OS also needs to be booted with Trident kernel image. The same can also be configured
with the "os" tag in the XML files as follows:
```
  <os>
    <type arch='x86_64' machine='pc-i440fx-eoan'>hvm</type>
    <kernel>/boot/vmlinuz-4.17.0-Trident+</kernel>
    <initrd>/boot/initrd.img-4.17.0-Trident+</initrd>
    <cmdline>console=ttyS0 root=/dev/sda1</cmdline>
    <boot dev='hd'/>
  </os>
```
Add `default_hugepagesz=2M` and `default_hugepagesz=1G` to cmdline attribute in 2MBHUGE.xml
and 1GBHUGE.xml respectively.

Refer to `vmconfigs/samples/` for all VM configurations used in the paper.


Additional Settings Post VM Installation
----------------------------------------

* Setup passwordless authentication between the host and VM (both ways). This can be done, for example, by
adding the RSA key of the host user to "$HOME/.ssh/authorized_keys" in the guest and vice-versa.

* Add the host and guest user to sudoers; they should be able to execute sudo without entering password.
An example `/etc/sudoers` entry is shown below:
```
ashish  ALL=(ALL:ALL) NOPASSWD:ALL
```

* Edit the ip address and user names of the host machine and VM in `Trident-MICRO21-artifact/scripts/configs.sh`
in the following fields:
```
GUESTUSER
GUESTIP
HOSTUSER
HOSTIP
```

* Configure the guest OS to auto mount the `Trident-MICRO21-artifact` repository on every boot in the same path as it is in the host using a network file system. An example `/etc/fstab` entry that uses SSHFS is shown below (assuming that the artifact is placed in the home directory of the user):
```
ashish@10.202.4.119:/home/ashish/Trident-MICRO21-artifact /home/ashish/Trident-MICRO21-artifact fuse.sshfs identityfile=/home/ashish/.ssh/id_rsa,allow_other,default_permissions 0 0
```

Preparing Datasets
------------------

The `canneal` and `svm` workloads require datasets to run. In addition, scripts to fragment physical memory
also require two large files. Scripts to download or generate all the required datasets are placed in
`Trident-MICRO21-artifact/datasets/`. Total disk space required for the datasets = memory size of socket 0 + 25GB.
Generate datasets (prior to running any experiment)  as:

```
$ Trident-MICRO21-artifact/scripts/prep_all_datasets.sh
```


Running the Experiments
-----------------------

Before you start running the experiments, boot your system with Trident (For HawkEye configurations, boot with HawkEye image),
and edit `configs.sh` as per your setup.

To run all experiments, execute:

```
$ Trident-MICRO21-artifact/scripts/run_all.sh
```

To run the experiments for individual figures, do:

 * Figure-1 - `Trident-MICRO21-artifact/scripts/run_figure_1.sh`
 * Figure-2 - `Trident-MICRO21-artifact/scripts/run_figure_2.sh`
 * Figure-9 - `Trident-MICRO21-artifact/scripts/run_figure_9.sh`
 * Figure-10 - `Trident-MICRO21-artifact/scripts/run_figure_10.sh`
 * Figure-11 - `Trident-MICRO21-artifact/scripts/run_figure_11.sh`
 * Figure-12 - `Trident-MICRO21-artifact/scripts/run_figure_12.sh`
 * Figure-13 - `Trident-MICRO21-artifact/scripts/run_figure_13.sh`

Refer to the corresponding run scripts for the list of supported benchmarks
and configurations.

All output logs will be redirected to `evaluation/`.


Prepare the Report
------------------

When you collected all or partial experimental data, you can compile them
in CSV format as follows:

```
$ Trident-MICRO21-artifact/scripts/compile_report.sh
```

CSV files for each figure and table will be redirected to
`Trident-MICRO21-artifact/report/`.

Paper Citation
--------------

Venkat Sai Ram, Ashish Panwar and Arkaprava Basu. 2021. Trident: Harnessing Micro-architectural
Resources for All Page Sizes in x86 Processors. In Proceedings of the 54th IEEE/ACM International
Symposium on Microarchitecture (MICRO-54), Athens, Greece.
