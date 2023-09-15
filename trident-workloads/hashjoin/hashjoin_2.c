#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>

#include "murmur3.h"

#ifdef _OPENMP
#include <omp.h>
#endif

#define ALIGNMET (1UL << 21)
#include <string.h>
static inline void allocate(void **memptr,size_t size)
{
    //printf("allocating %zu MB memory\n", size >> 20);
  if (posix_memalign(memptr, ALIGNMET, size)) {
    printf("ENOMEM\n");
    exit(1);
  }
  memset(*memptr, 0, size);
}

///< the name of the shared memory file created
#define CONFIG_SHM_FILE_NAME "/tmp/alloctest-bench"

struct htelm {
  uint64_t key;
  uint64_t payload[128];
};

struct element {
    uint64_t key;
    uint64_t payload[4];
};

//#define DEFAULT_HASH_SIZE (8UL << 30)
//#define DEFAULT_HASH_SIZE (8UL << 26)
#define DEFAULT_HASH_SIZE (4 << 20)
#define DEFAULT_NKEYS   (8UL << 23)
#define DEFAULT_NLOOKUP 4000000000

//#define L1_HASH_TABLE_SIZE 8192
#define L1_HASH_TABLE_SIZE 4096
#define L2_HASH_TABLE_SIZE (512)

struct htelm ***l1_hash_table;

int
real_main(int argc, char *argv[]);
int
real_main(int argc, char *argv[])
{
    size_t hashsize = DEFAULT_HASH_SIZE;
    size_t nlookups = DEFAULT_NLOOKUP;
    if (argc == 3) {
        hashsize = strtol(argv[1], NULL, 10);
        nlookups = strtol(argv[2], NULL, 10);
    } else if(argc == 2) {
        hashsize = strtol(argv[1], NULL, 10);
    }

    uint32_t seed = 42;  


  struct htelm *htelms, *htelms2;
  allocate((void **)&htelms, L1_HASH_TABLE_SIZE * L2_HASH_TABLE_SIZE * sizeof(*htelms));
  allocate((void **)&htelms2, L1_HASH_TABLE_SIZE * L2_HASH_TABLE_SIZE * sizeof(*htelms2));

    printf("L1 Table\n");
    allocate((void **)&l1_hash_table, L1_HASH_TABLE_SIZE * sizeof(struct htelm **));
    size_t ht_size = L1_HASH_TABLE_SIZE * sizeof(uint64_t *);
    for (size_t i = 0; i < L1_HASH_TABLE_SIZE; i++) {
        //printf("L2 Table[%zu]\n", i);

        allocate((void **)&l1_hash_table[i], L2_HASH_TABLE_SIZE * sizeof(struct htelm *));
      struct htelm **ht = l1_hash_table[i];
        for (size_t j = 0; j < L2_HASH_TABLE_SIZE; j++) {

              if (j % 2) {
                ht[j] = &htelms[j];
                ht[j]->key = j;
              } else {
                ht[j] = &htelms[j];
                ht[j]->key = j;
              }
            }

            ht_size += L2_HASH_TABLE_SIZE;
    }


    printf("Allocated Hash Tables of size %zu kB\n", 
          (ht_size * sizeof(uint64_t)) >> 10);

    printf("Data Table\n");
  struct element *table;
  allocate((void **)&table, DEFAULT_NKEYS * sizeof(*table));
  for (size_t i = 0; i < DEFAULT_NKEYS; i++) {
    table[i].key = (i) % (L1_HASH_TABLE_SIZE * L2_HASH_TABLE_SIZE);
  }



  fprintf(stderr, "signalling readyness to %s\n",
          CONFIG_SHM_FILE_NAME ".ready");
  FILE *fd2 = fopen(CONFIG_SHM_FILE_NAME ".ready", "w");

  if (fd2 == NULL) {
    fprintf(stderr,
            "ERROR: could not create the shared memory file descriptor\n");
    exit(-1);
  }

  usleep(250);

  size_t matches = 0;
  
  #ifdef _OPENMP
  #pragma omp parallel for
  #endif
  for (size_t i = 0; i < nlookups; i++) {
    uint64_t hash[2];                /* Output for the hash */
    size_t idx = i % DEFAULT_NKEYS;
    MurmurHash3_x64_128(&table[idx].key, sizeof(&table[idx].key), seed, hash);

    struct htelm **ht = l1_hash_table[hash[0] % L1_HASH_TABLE_SIZE];

    if (ht) {
        struct htelm *e = ht[hash[1] % L2_HASH_TABLE_SIZE];
        if (e->key) {
          matches++;  
        }
    } else {
        printf("ELEMENT WAS NULL???\n");
    }

    table[idx].payload[0] += 1;
  }

  printf("got %zu matches\n", matches);





  fprintf(stderr, "signalling done to %s\n",
          CONFIG_SHM_FILE_NAME ".done");
  FILE *fd1 = fopen(CONFIG_SHM_FILE_NAME ".done", "w");

  if (fd1 == NULL) {
    fprintf(stderr,
            "ERROR: could not create the shared memory file descriptor\n");
    exit(-1);
  }
}

