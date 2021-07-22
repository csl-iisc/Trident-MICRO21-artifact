#!/usr/bin/python3

import os

root = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
sample_src=os.path.join(root, 'datasets/canneal_small')


def prepare_dataset():
    # -- get the size of sample file
    sample_size = int(os.stat(sample_src).st_size)
    print(sample_size)

    # --- get total memory size of node-0
    cmd = 'numactl -H | grep \'node 0 size\' | awk \'{print $4}\''
    total = os.popen(cmd).read().strip()
    total = int(total) * 1024 * 1024
    print('nr_copies = %d' % (total/sample_size))
    nr_copies = int((total/sample_size)/2)
    os.mkdir(os.path.join(root, 'datasets/fragmentation'))
    # --- prepare file-1
    print('preparing file-1...')
    for i in range(nr_copies):
        src = os.path.join(root, 'datasets/canneal_small')
        dst = os.path.join(root, 'datasets/fragmentation/file-1')
        cmd = 'cat %s >> %s' %(src, dst)
        os.system(cmd)

    print('preparing file-2...')
    # --- copy file-1 to file-2
    src = os.path.join(root, 'datasets/fragmentation/file-1')
    dst = os.path.join(root, 'datasets/fragmentation/file-2')
    cmd = 'cp %s %s' %(src, dst)
    os.system(cmd)

if __name__ == '__main__':
    if not os.path.exists(sample_src):
        print('generating sample file from canneal first...')
        src = os.path.join(root, 'datasets/prepare_canneal_datasets.sh')
        cmd = str(src) + ' small'
        print(cmd)
        os.system(cmd)

    print('preparing dataset for fragmenting memory...')
    prepare_dataset()
