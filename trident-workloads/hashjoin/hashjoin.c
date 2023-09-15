#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>

#include "murmur3.h"

#ifdef _OPENMP
#include <omp.h>
#endif

//#define DEFAULT_HASH_SIZE (8UL << 30)
//#define DEFAULT_HASH_SIZE (8UL << 26)
//#define DEFAULT_HASH_SIZE ((35UL * 1024 * 1024) / 8)

// +#ifdef _OPENMP
// +#define DEFAULT_HASH_SIZE ((4UL * 35UL * 1024 * 1024) / 8)
// +#define DEFAULT_NKEYS   (16UL << 30)
// +#define DEFAULT_NLOOKUP 50000000000
// +#else
// +#define DEFAULT_HASH_SIZE ((35UL * 1024 * 1024) / 8)
// +#define DEFAULT_NKEYS   (1UL << 29)


#ifdef _OPENMP
#define DEFAULT_HASH_SIZE ((2048UL * 1024 * 1024) / 8)
#define DEFAULT_NKEYS   (2UL << 30)
#define DEFAULT_NLOOKUP 5000000000
#else
#define DEFAULT_HASH_SIZE ((2048UL * 1024 * 1024) / 8)
#define DEFAULT_NKEYS   (128UL * 1024 * 1024)
#define DEFAULT_NLOOKUP 500000000
#endif


///< the name of the shared memory file created
#define CONFIG_SHM_FILE_NAME "/tmp/alloctest-bench"

#define ALIGNMET (1UL << 21)
#include <string.h>
static inline void allocate(void **memptr,size_t size)
{
  printf("allocating %zu MB memory with large-page alignment\n", size >> 20);
  if (posix_memalign(memptr, ALIGNMET, size)) {
    printf("ENOMEM\n");
    exit(1);
  }
  memset(*memptr, 0, size);
}

struct element {
    uint64_t key;
    uint64_t payload[15];
};

struct htelm {
  uint64_t key;
  uint64_t payload[7];
};


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
  struct htelm **hashtable;
  allocate((void **)&hashtable, hashsize * sizeof(struct htelm *));

  printf("Hashtable Size: %zuMB\n", (hashsize * sizeof(struct htelm *)) >> 20);
  printf("Datatable Size Size: %zuMB\n", (DEFAULT_NKEYS * sizeof(struct element)) >> 20);
  printf("Element Size: %zu MB\n",  (hashsize * sizeof(struct htelm)) >> 20);
  printf("Total: %zu MB\n", 
      ((hashsize * sizeof(*hashtable)) 
        + (DEFAULT_NKEYS * sizeof(struct element)) 
        + (hashsize * sizeof(struct htelm))) >> 20);

  #define NUM_REGIONS 4
  struct htelm *htelms[NUM_REGIONS];
  for (size_t i = 0; i < NUM_REGIONS; i++) {
     allocate((void **)&htelms[i], hashsize * sizeof(struct htelm) / NUM_REGIONS);
  }
 
  for (size_t i = 0; i < hashsize; i++) {
     struct htelm *hte = htelms[i % NUM_REGIONS];
      hashtable[i] = &hte[i / NUM_REGIONS];
      hashtable[i]->key = i+1;
  }

  struct element *table;
  allocate((void **)&table, DEFAULT_NKEYS * sizeof(struct element ));
  for (size_t i = 0; i < DEFAULT_NKEYS; i++) {
    table[i].key = i;
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
  size_t loaded = 0;

  #ifdef _OPENMP
  #pragma omp parallel for reduction(+:matches)
  #endif
  for (size_t i = 0; i < nlookups; i++) {
    uint64_t hash[2];                /* Output for the hash */
    size_t idx = i % DEFAULT_NKEYS;
    MurmurHash3_x64_128(&table[idx].key, sizeof(&table[idx].key), seed, hash);
    struct htelm *e = hashtable[hash[0] % hashsize];
    if (e && e->key) {
            matches++;
    } 

    e = hashtable[hash[1] % hashsize];
    if (e && e->key) {
        matches++;
    }

    e = hashtable[(hash[0] << 2) % hashsize];
    if (e && e->key) {
            matches++;
    } 

    e = hashtable[(hash[1] << 2) % hashsize];
    if (e && e->key) {
        matches++;
    }    
  }

  printf("got %zu matches / %zu \n", matches, loaded);

  fprintf(stderr, "signalling done to %s\n",
          CONFIG_SHM_FILE_NAME ".done");
  FILE *fd1 = fopen(CONFIG_SHM_FILE_NAME ".done", "w");

  if (fd1 == NULL) {
    fprintf(stderr,
            "ERROR: could not create the shared memory file descriptor\n");
    exit(-1);
  }

  return 0;
}
