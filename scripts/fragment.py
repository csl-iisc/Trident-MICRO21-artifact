#!/usr/bin/python

'''
This script creates fragmentation by reading a large file randomly in pages.
This it will keep on doing for a specific time which has to be prementioned.
This we will do it with multi threaded
'''

import sys, time, random, string, os
from multiprocessing import Process, Manager

FILE_NAME1 = sys.argv[1]
FILE_NAME2 = sys.argv[2]
#FILE_SIZE = int(sys.argv[2])
#BLOAT = int(sys.argv[3])
NR_SECONDS = int(sys.argv[3])
NR_THREADS = int(sys.argv[4])

#print 'FILE_NAME', FILE_NAME
#print 'FILE_SIZE', FILE_SIZE
#print 'BLOAT', BLOAT
print 'NR_SECONDS', NR_SECONDS
print 'NR_THREADS', NR_THREADS

ns = Manager().Namespace()
ns.ops = 0

def fragment_file():
        #print 'entered new process'
        #print 'opening file'
        f = open(FILE_NAME1, 'r')
        f.seek(0, os.SEEK_END)
        FILE_SIZE = f.tell();
        #print 'opened file'
        ops = 0
        t_end = time.time() + NR_SECONDS
        while time.time() < t_end:
                r = random.randint(0, FILE_SIZE - 10);
                f.seek(r)
                t = f.read(20);
                ops += 1;
        f.close()
        ns.ops += ops

def fragment_file2():
        #print 'opening file'
        f = open(FILE_NAME2, 'r')
        f.seek(0, os.SEEK_END)
        FILE_SIZE = f.tell();
        #print 'opened file'
        ops = 0
        t_end = time.time() + NR_SECONDS
        while time.time() < t_end:
                r = random.randint(0, FILE_SIZE - 10);
                f.seek(r)
                t = f.read(20);
                ops += 1;
        f.close()
        ns.ops += ops

procs = []

for i in range(NR_THREADS):
        #print 'creating new process'
        p = Process(target = fragment_file)
        p2 = Process(target = fragment_file2)
        #print 'created new process'
        procs.append(p)
        procs.append(p2)
        #print 'starting thread', i
        p.start()
        p2.start()
        print 'started thread', i

print 'Created the threads. Waiting for then to complete'
for p in procs:
        p.join()
print 'All threads joined'
procs = []

print 'Read operations performed are :', ns.ops;

