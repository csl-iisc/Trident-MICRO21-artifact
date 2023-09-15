/*
 * Copyright (c) 2014 ETH Zurich.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE file.
 * If you do not find this file, copies can be found by writing to:
 * ETH Zurich D-INFK, Universitaetsstrasse 6, CH-8092 Zurich. Attn: Systems Group.
 */

#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <limits.h>
#include <assert.h>
#include <sys/mman.h>
#include <fcntl.h>      /* open */
#include <unistd.h>     /* exit */


#define DEBUG(x...) //printf("DBG: " x)

/*
 * ----------------------------------------------------------------------------
 * Benchmark Settings
 * ----------------------------------------------------------------------------
 */

/// the number of benchmark rounds to execute

#define DIM_MAP_SHARED       0
#define DIM_MAP_SHARED_EAGER 1
#define DIM_UNMAP_SHARED     2
#define DIM_PROTECT_SHARED   3
#define DIM_MAP              4
#define DIM_MAP_EAGER        5
#define DIM_UNMAP            6
#define DIM_PROTECT          7



#define DIMENSIONS (8)
uint64_t *measurements[DIMENSIONS];


size_t NROUNDS = 5000;
size_t NPAGES = 1;
size_t PAGESIZE = 4096;
bool MITOSIS = false;

#define HUGE_PAGE_SIZE (2UL << 20)
#define MAP_HUGE_2MB    (21 << MAP_HUGE_SHIFT)
#define MAP_HUGE_PAGE (MAP_HUGE_2MB | MAP_HUGETLB)

static inline uint64_t rdtscp(void)
{
    uint32_t eax, edx;
    // why is "ecx" in clobber list here, anyway? -SG&MH,2017-10-05
    __asm volatile ("rdtscp" : "=a" (eax), "=d" (edx) :: "ecx", "memory");
    return ((uint64_t)edx << 32) | eax;
}

#define bench_tscoverhead() 30UL

static inline uint64_t calculate_time(uint64_t tsc_start,
                                      uint64_t tsc_end)
{
    uint64_t result;
    if (tsc_end < tsc_start) {
        result = (LONG_MAX - tsc_start) + tsc_end - bench_tscoverhead();
    } else {
        result = (tsc_end - tsc_start - bench_tscoverhead());
    }

    if (result < (tsc_end - tsc_start)) {
        return result;
    }

    DEBUG("result: %lu / %lu / overhead: %lu\n", result,
                 tsc_end - tsc_start, bench_tscoverhead());

    return result;
}

#define MAP_PROT   (PROT_READ | PROT_WRITE)

static uint64_t run_benchmark_map(int fd, int flags, size_t bytes, bool eager, void **addr, char *val)
{
    volatile char *a;
    uint64_t tsc_start, tsc_end;
    if (eager) {
        tsc_start = rdtscp();
        a = (char *)mmap(NULL, bytes, MAP_PROT, flags | MAP_POPULATE, fd, 0);
        tsc_end = rdtscp();
        if (a == MAP_FAILED) {
            perror("MAP FAILED!!!!\n");
            exit(1);
        }
    } else {
        tsc_start = rdtscp();
        a = (char *)mmap(NULL, bytes, MAP_PROT, flags, fd, 0);
        if (a == MAP_FAILED) {
            perror("MAP FAILED!!!! 2\n");
            exit(1);
        }
        volatile char s = 0;
        for (size_t i = 0; i < bytes; i += PAGESIZE) {
            s += a[i];
        }
        tsc_end = rdtscp();
        *val = s;
    }

    *addr = (void *)a;

    return calculate_time(tsc_start, tsc_end);
}

static uint64_t run_benchmark_mprotect(void *addr, size_t bytes)
{
    uint64_t tsc_start = rdtscp();
    mprotect(addr, bytes, PROT_READ);
    mprotect(addr, bytes, PROT_WRITE);
    uint64_t tsc_end = rdtscp();

    return calculate_time(tsc_start, tsc_end) / (2);
}

static uint64_t run_benchmark_unmap(void *addr, size_t bytes)
{
    uint64_t tsc_start = rdtscp();
    munmap(addr, bytes);
    uint64_t tsc_end = rdtscp();

    return calculate_time(tsc_start, tsc_end);
}

static int comp(const void *a, const void *b)
{
  uint64_t ai = *((uint64_t *)a);
  uint64_t bi = *((uint64_t *)b);
  if (ai < bi) {
    return -1;
  } else if (ai == bi) {
    return 0;
  } else {
    return 1;
  }
}

static void dump_analysis(size_t npages, uint64_t *vals, size_t num, char *label)
{
  qsort(vals, num, sizeof(uint64_t), comp);

  uint64_t min = vals[0];
  uint64_t max = vals[num -1];
  uint64_t avg = vals[num/2];
  uint64_t ninefive = vals[(size_t)((num - 1)*0.99)];

  printf("%s\t%zu\t%zu\t%u\t%lu\t%lu\t%lu\t%lu\t%lu\t%lu\t%lu\t%lu\n", label,npages,PAGESIZE,MITOSIS,
      min, avg, ninefive, max,
      min/NPAGES, avg/NPAGES, ninefive/NPAGES,max/NPAGES);
}


#define CONFIG_SHM_FILE_NAME "mmapbench"


/*
\RA{Configurations: Page Size: 4kB|2MB, Memory: Anonymous|Shared, Mitosis:
On|Off, THP: On|Off, Map: Eager|OnDemand}
*/

void run_shared(void)
{
    size_t size = NPAGES * PAGESIZE;

    DEBUG("<shared>\n");

    int fd = shm_open(CONFIG_SHM_FILE_NAME, O_RDWR | O_CREAT, 0600);
    if (fd < 0) {
        fprintf(stderr, "ERROR: could not create the shared memory file descriptor\n");
        exit(1);
        return;
    }

    /* truncate it to be of size memory */
    if (ftruncate(fd, 2UL * size)) {
        shm_unlink(CONFIG_SHM_FILE_NAME);
        fprintf(stderr, "ERROR: could not truncate\n");
        exit(1);
        return;
    }

    int MAP_FLAGS = (MAP_SHARED | MAP_NORESERVE);
    if (PAGESIZE == HUGE_PAGE_SIZE) {
        MAP_FLAGS |= MAP_HUGETLB | MAP_HUGE_2MB;
    }

    void *table_unused = mmap(NULL, size * 2UL, MAP_PROT,
                              MAP_FLAGS | MAP_POPULATE, fd, 0);
    if (table_unused  == MAP_FAILED) {
      perror("MAP FAILED for addrs\n");
      exit(-1);
    }
    memset(table_unused, 0,  NPAGES * 2UL * PAGESIZE);

    char val = 0;
    for (uint32_t round = 0; round < NROUNDS; round++) {
        void *addr;
        measurements[DIM_MAP_SHARED][round] = run_benchmark_map(fd, MAP_FLAGS, size, false, &addr, &val);
        munmap(addr, size);
        measurements[DIM_MAP_SHARED_EAGER][round] = run_benchmark_map(fd, MAP_FLAGS, size, true, &addr, &val);
        measurements[DIM_PROTECT_SHARED][round] = run_benchmark_mprotect(addr, size);
        measurements[DIM_UNMAP_SHARED][round] = run_benchmark_unmap(addr, size);
    }

    close(fd);

    /* clean up file */
    shm_unlink(CONFIG_SHM_FILE_NAME);

    DEBUG("</shared>\n");
}

void run_non_shared(void)
{

    DEBUG("<private>\n");


    size_t size = NPAGES * PAGESIZE;
    int MAP_FLAGS = (MAP_PRIVATE | MAP_NORESERVE | MAP_ANON);
    if (PAGESIZE == HUGE_PAGE_SIZE) {
        MAP_FLAGS |= MAP_HUGETLB | MAP_HUGE_2MB;
    }
    char val = 0;
    for (uint32_t round = 0; round < NROUNDS; round++) {
        void *addr;
        measurements[DIM_MAP][round] = run_benchmark_map(-1, MAP_FLAGS, size, false, &addr, &val);
        munmap(addr, size);
        measurements[DIM_MAP_EAGER][round] = run_benchmark_map(-1, MAP_FLAGS, size, true, &addr, &val);
        measurements[DIM_PROTECT][round] = run_benchmark_mprotect(addr, size);
        measurements[DIM_UNMAP][round] = run_benchmark_unmap(addr, size);
    }

    DEBUG("</private>\n");
}


int main(int argc, char *argv[])
{
    int c;
    while ((c = getopt (argc, argv, "s:mn:l")) != -1) {
        switch (c) {
        case 'n' :
            NROUNDS = strtol(optarg, NULL, 10);
            break;
        case 's':
            NPAGES = strtol(optarg, NULL, 10);
            break;
        case 'm':
            MITOSIS = true;
            break;
        case 'l' :
            PAGESIZE = HUGE_PAGE_SIZE;
            break;
        case 'h':
            printf("usage: %s [-n N] [-m] [-l]\n", argv[0]);
            printf("s: num pages, m: mitosis, l: largepages\n");
            return 0;
        case '?':
            switch(optopt) {
                case 'n' :
                case 's' :
                    fprintf (stderr, "Option -%c requires an argument.\n", optopt);
                    return -1;
                default:
                    fprintf (stderr, "Unknown option `-%c'.\n", optopt);
                return -1;
            }
        }
    }

    DEBUG("mmap benchmark started: NROUNDS=%zu, NPAGES=%zu, PAGESIZE=%zu\n",
              NROUNDS, NPAGES, PAGESIZE);

    uint64_t *resdata = calloc(NROUNDS * DIMENSIONS, sizeof(uint64_t));
    if (resdata == NULL) {
        printf("NO MEMORY!");
        exit(1);
    }

    for (size_t i = 0; i < DIMENSIONS; i++) {
        measurements[i] = &resdata[i * NROUNDS];
    }

    size_t npages_max = NPAGES;
  //  for (NPAGES = 1; NPAGES <= npages_max; NPAGES *= 2) {
            run_shared();
            run_non_shared();

        printf("label\tnpages\tpagesize\tmitosis\tmin\tavg\t99th\tmax\tmin/nmages\tavg/npages\t99th/page\tmax/npages\n");

        //dump_analysis(NPAGES, measurements[DIM_MAP_SHARED], NROUNDS, "MAP_SHARED");
        dump_analysis(NPAGES, measurements[DIM_MAP_SHARED_EAGER], NROUNDS, "MAP_SHARED");
        dump_analysis(NPAGES, measurements[DIM_PROTECT_SHARED], NROUNDS, "PROTECT_SHARED");
        dump_analysis(NPAGES, measurements[DIM_UNMAP_SHARED], NROUNDS, "UNMAP_SHARED");
        //dump_analysis(NPAGES, measurements[DIM_MAP], NROUNDS, "MAP");
        dump_analysis(NPAGES, measurements[DIM_MAP_EAGER], NROUNDS, "MAP");
        dump_analysis(NPAGES, measurements[DIM_PROTECT], NROUNDS, "PROTECT");
        dump_analysis(NPAGES, measurements[DIM_UNMAP], NROUNDS, "UNMAP");

        printf("\n");
  //  }




    free(resdata);
}
