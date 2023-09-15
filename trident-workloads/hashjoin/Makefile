program = HashJoin
program2 = HashJoin2
source = hashjoin.c murmurhash.c
source2 = hashjoin2.c murmurhash.c

obj = $(source:.c=.o)
objomp = $(source:.c=.o-omp)
obj2 = $(source2:.c=.o)
obj2omp = $(source2:.c=.o-omp)

# Standard Flags
CFLAGS := -std=gnu99 -Wall  -O3

# compiler
CC = gcc

$(program): $(obj) Makefile
	$(CC) $(CFLAGS) $(obj) -o $@ $(LDFLAGS)

$(program2): $(obj2) Makefile
	$(CC) $(CFLAGS) $(obj2) -o $@ $(LDFLAGS)	

libhashjoin.a: $(obj) Makefile
	ar rcs $@ $(obj)

libhashjoinomp.a: $(objomp) Makefile
	ar rcs $@ $(objomp)	

libhashjoin2.a: $(obj2) Makefile
	ar rcs $@ $(obj2)

libhashjoin2omp.a: $(obj2omp) Makefile
	ar rcs $@ $(obj2omp)


%.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

%.o-omp: %.c Makefile
	$(CC) $(CFLAGS) -fopenmp -c $< -o $@

clean:
	rm -rf $(program) $(obj)
	rm -f *.a
	rm -f *.o-omp
