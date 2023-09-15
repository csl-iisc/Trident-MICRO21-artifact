CC = gcc
CFLAGS = -O2

all: bench_memops

bench_memops : mmapbench.c
	$(CC) $(CFLAGS) mmapbench.c -o bench_memops  -lnuma -lrt

clean:
	rm -f bench_memops
