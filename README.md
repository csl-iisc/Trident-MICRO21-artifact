Trident MICRO'21 Artifact Evaluation
=====================================

This repository contains scripts and other supplementary material
for the MICRO'21 artifact evaluation of the paper **Trident: Harnessing
Micro-architectural Resources for All Page Sizes in x86 Processors **.

Authors
-------
 
 * Venkat Sri Sai Ram (Indian Institute of Science)
 * Ashish Panwar (Indian Institute of Science)
 * Arkaprava Basu (Indian Institute of Science)


Directory Structure
-------------------

 * `bin/` contains all the binaries
 * `datasets/` contains the datasets required for the binaries
 * `scripts/` contains scripts to run the experiments
 * `evaluation/` experimental logs are redirected here
 * `vmconfigs/` stores libvirt's XML configuration files
 * `report/` will contain processed logs in CSV format


Hardware Dependencies
---------------------

We recommend an Intel Skylake node with 18 cores (36 threads) and 192GB memory.
Other x86_64 servers with similar memory and compute capability should produce comparable results.

Software Dependencies
---------------------

The scripts and binaries are tested on Ubuntu 18.04 LTS. Other 
Linux distributions may work, but are not tested.

In addition to the packages shipped with Ubuntu 18.04 LTS the following 
packages are required:

```
sudo apt update
sudo apt install build-essential bison bc \
libncurses-dev flex libssl-dev automake \
libelf-dev libnuma-dev python3 git \
wget libncurses5-dev libevent-dev \
libreadline-dev libtool autoconf \
qemu-kvm libvirt-bin bridge-utils \
virtinst virt-manager hugepages \
libgfortran3 libhugetlbfs-dev

```                       

Obtaining Source Code and Compile
---------------------------------

The source of Trident and HawkEye [ASPLOS'19] kernels are available on GitHub and included as
public submodules. To obtain the source code, initialize the git submodules:

```
git clone https://github.com/csl-iisc/Trident-MICRO21-artifact
cd Trident-MICRO21-artifact
PROJECT_DIR=$(pwd)
git submodule init
git submodule update
```

To compile Trident, do:

```
cd $PROJECT_DIR/sources/Trident
git fetch --all; git checkout trident
make menuconfig; make -j $(nproc)
sudo make modules_install; sudo make install
```

To compile HawkEye, do:

```
cd $PROJECT_DIR/sources/HawkEye;
git fetch --all; git checkout hawkeye
make menuconfig; make -j $(nproc)
sudo make modules_install; sudo make install
```

Enable CONFIG_TRANSPARENT_HUGEPAGE while compiling kernel images.

Install and Create Virtual Machine Configurations
-------------------------------------------------

Install a virtual machine using command line (choose ssh-server when prompted for package installation):

```
virt-install --name trident --ram 8192 --disk path=~/trident.qcow2,size=60 \
--vcpus 8 --os-type linux --os-variant generic --network bridge=virbr0 \
--graphics none --console pty,target_type=serial \
--location 'http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
--extra-args 'console=ttyS0,115200n8 serial'
```
Once installed, use the following script to prepare VM configuration files:
```
$PROJECT_DIR/scripts/gen_vmconfigs.py trident

```
If it works well, skip the rest of this subsection. Otherwise you may have to manually create VM configurations following the instructions provided below.

Copy the default XML configuration file in four files under `vmconfigs/`:
```
virsh dumpxml trident > $PROJECT_DIR/vmconfigs/4KB.xml
virsh dumpxml trident > $PROJECT_DIR/vmconfigs/2MBHUGE.xml
virsh dumpxml trident > $PROJECT_DIR/vmconfigs/1GBHUGE.xml
virsh dumpxml trident > $PROJECT_DIR/vmconfigs/HAWKEYE.xml
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

To boot the VM with HawkEye kernel, add the following "os" tag in `vmconfigs/HAWKEYE.xml`:
```
  <os>
    <type arch='x86_64' machine='pc-i440fx-eoan'>hvm</type>
    <kernel>/boot/vmlinuz-4.3.0-HawkEye+</kernel>
    <initrd>/boot/initrd.img-4.3.0-HawkEye+</initrd>
    <cmdline>console=ttyS0 root=/dev/sda1</cmdline>
    <boot dev='hd'/>
  </os>
```

Refer to `$PROJECT_DIR/vmconfigs/samples/` for all VM configurations used in the paper.


Additional Settings Post VM Installation
----------------------------------------

* Setup passwordless authentication between the host and VM (both ways). This can be done, for example, by
adding the RSA key of the host user to "$HOME/.ssh/authorized_keys" in the guest and vice-versa.

* Add the host and guest user to sudoers; they should be able to execute sudo without entering password.
An example `/etc/sudoers` entry is shown below:
```
venkat  ALL=(ALL:ALL) NOPASSWD:ALL
```

* Edit the ip address and user name of the VM in `$PROJECT_DIR/scripts/configs.sh`
in the following fields:
```
GUESTUSER
GUESTIP
```

* Configure the guest OS to auto mount the `Trident-MICRO21-artifact` repository on every boot in the same path as it is in the host using a network file system. An example `/etc/fstab` entry that uses SSHFS is shown below (assuming that the artifact is placed in the home directory of the user):
```
venkat@10.202.4.119:/home/venkat/Trident-MICRO21-artifact /home/venkat/Trident-MICRO21-artifact fuse.sshfs identityfile=/home/venkat/.ssh/id_rsa,allow_other,default_permissions 0 0
```

Preparing Datasets
------------------

The `canneal` and `svm` workloads require datasets to run. In addition, scripts to fragment physical memory
also require two large files. Individual scripts to prepare these datasets are placed in `$PROJECT_DIR/datasets/`. Total disk space
required for datasets = memory size of socket 0 + 30GB.
Generate all datasets at once (prior to running any experiment) as:

```
$PROJECT_DIR/scripts/prep_all_datasets.sh
```


Running the Experiments
-----------------------

Before you start running the experiments, boot your system with Trident (For HawkEye configurations, boot with HawkEye image),
and edit `$PROJECT_DIR/scripts/configs.sh` as per your setup.

To run the experiments for individual figures, do:

 * Figure-1 - `$PROJECT_DIR/scripts/run_figure_1.sh`
 * Figure-2 - `$PROJECT_DIR/scripts/run_figure_2.sh`
 * Figure-9 - `$PROJECT_DIR/scripts/run_figure_9.sh`
 * Figure-10 - `$PROJECT_DIR/scripts/run_figure_10.sh`
 * Figure-11 - `$PROJECT_DIR/scripts/run_figure_11.sh`
 * Figure-12 - `$PROJECT_DIR/scripts/run_figure_12.sh`
 * Figure-13 - `$PROJECT_DIR/scripts/run_figure_13.sh`

Refer to the corresponding run scripts for the list of supported benchmarks
and configurations. Some configurations requires rebooting host system with
different command-line parameters (`default_hugepagesz=1G` for 1GB Hugetlbfs
experiments and with HawkEye kernel image for evaluating HawkEye). Wherever
applicable, follow the steps mentioned in each script to run these configurations.

All output logs will be redirected to `$PROJECT_DIR/evaluation/`.


Prepare the Report
------------------

When you collected all or partial experimental data, you can compile them
in CSV format as follows:

```
$PROJECT_DIR/scripts/compile_report.sh
```

CSV files will be redirected to `$PROJECT_DIR/report/`.

Paper Citation
--------------

Venkat Sri Sai Ram, Ashish Panwar and Arkaprava Basu. 2021. Trident: Harnessing Micro-architectural Resources for All Page Sizes in x86 Processors. In Proceedings of the 54th IEEE/ACM International Symposium on Microarchitecture (MICRO-54), Athens, Greece.
