all: btree canneal graph500 gups hashjoin liblinear xsbench memops

clean-all: clean-btree clean-canneal clean-graph500 clean-gups clean-hashjoin \
		   clean-liblinear clean-xsbench clean-memops


###############################################################################
# Workloads
###############################################################################

CC = gcc
CXX = g++

INCLUDES=-Icommon

# cflags used
CFLAGS=-O3 -march=native -static
CXXFLAGS=-O3 -march=native -static

# common libraries used
COMMON_LIBS=-lrt -ldl -lnuma -lpthread -lm

# common main functions for multithreaded, single threaded and page-table dump
COMMON_MAIN_M=common/main-mt.c
COMMON_MAIN_S=common/main-st.c
COMMON_MAIN_D=common/main-ptdump.c

sources/mitosis-workloads/README.md:
	echo "initialized git submodules"
	git submodule init 
	git submodule update


###############################################################################
# BTree
###############################################################################

btree/libbtree.a : 
	+$(MAKE) -C btree libbtree.a

btree/libbtreeomp.a : 
	+$(MAKE) -C btree libbtreeomp.a

bin/bench_btree_st : btree/libbtree.a $(COMMON_MAIN_S)
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		btree/libbtree.a  -o $@  $(COMMON_LIBS) 

bin/bench_btree_mt : btree/libbtreeomp.a $(COMMON_MAIN_M) 
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_M) \
		btree/libbtreeomp.a -fopenmp -o $@  $(COMMON_LIBS) 		

bin/bench_btree_dump : btree/libbtree.a $(COMMON_MAIN_D)
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_D) \
		btree/libbtree.a  -o $@  $(COMMON_LIBS) 

btree : bin/bench_btree_st bin/bench_btree_dump bin/bench_btree_mt

clean-btree :
	+$(MAKE) -C btree clean


###############################################################################
# Canneal
###############################################################################

canneal/libcanneal.a :
	+$(MAKE) -C canneal

canneal/libcannealmt.a :
	+$(MAKE) -C canneal


bin/bench_canneal_mt : canneal/libcannealmt.a  $(COMMON_MAIN_M)
	$(CXX) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_M) \
		canneal/libcannealmt.a  -o $@  $(COMMON_LIBS) 

bin/bench_canneal_st : canneal/libcanneal.a  $(COMMON_MAIN_S) 
	$(CXX) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		canneal/libcanneal.a -fopenmp -o $@  $(COMMON_LIBS) 

canneal : bin/bench_canneal_st bin/bench_canneal_mt

clean-canneal :
	+$(MAKE) -C canneal clean	


###############################################################################
# Graph500
###############################################################################


graph500/seq-list/seq-list.a:
	+$(MAKE) -C graph500 seq-list/seq-list.a

graph500/omp-csr/omp-csr.a:
	+$(MAKE) -C graph500 omp-csr/omp-csr.a

graph500/seq-csr/seq-csr.a:
	+$(MAKE) -C graph500 seq-csr/seq-csr.a


bin/bench_graph500_st : graph500/seq-csr/seq-csr.a $(COMMON_MAIN_S)
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		graph500/seq-csr/seq-csr.a -o $@  $(COMMON_LIBS) 

bin/bench_graph500_mt  : graph500/omp-csr/omp-csr.a $(COMMON_MAIN_M) 
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_M) \
		graph500/omp-csr/omp-csr.a -fopenmp -o $@  $(COMMON_LIBS) 		

graph500 : bin/bench_graph500_mt bin/bench_graph500_st

clean-graph500 :
	+$(MAKE) -C graph500 clean	


###############################################################################
# Gups
###############################################################################

gups/libgups.a : 
	+$(MAKE) -C gups libgups.a

gups/libgupstoy.a : 
	+$(MAKE) -C gups libgupstoy.a	

bin/bench_gups_st: gups/libgups.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		gups/libgups.a -o $@  $(COMMON_LIBS)

bin/bench_gups_toy: gups/libgupstoy.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		gups/libgupstoy.a -o $@  $(COMMON_LIBS)		

gups : bin/bench_gups_st bin/bench_gups_toy

clean-gups :
	+$(MAKE) -C gups clean


###############################################################################
# HashJoin
###############################################################################


hashjoin/libhashjoin.a : 
	+$(MAKE) -C hashjoin libhashjoin.a	

hashjoin/libhashjoinomp.a : 
	+$(MAKE) -C hashjoin libhashjoinomp.a		

bin/bench_hashjoin_st: hashjoin/libhashjoin.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) $(COMMON_MAIN_S) \
		hashjoin/libhashjoin.a -o $@  $(COMMON_LIBS)

bin/bench_hashjoin_mt: hashjoin/libhashjoinomp.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) -fopenmp \
		$(COMMON_MAIN_M) hashjoin/libhashjoinomp.a -o $@  $(COMMON_LIBS)

bin/bench_hashjoin_dump: hashjoin/libhashjoinomp.a
	$(CC) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) -fopenmp \
		$(COMMON_MAIN_D) hashjoin/libhashjoinomp.a -o $@  $(COMMON_LIBS)

hashjoin : bin/bench_hashjoin_st bin/bench_hashjoin_mt bin/bench_hashjoin_dump

clean-hashjoin :
	+$(MAKE) -C hashjoin clean


###############################################################################
# LibLinear
###############################################################################

liblinear/liblinear.a :
	+$(MAKE) -C liblinear liblinear.a

bin/bench_liblinear_mt : liblinear/liblinear.a 
	$(CXX) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) -fopenmp \
		$(COMMON_MAIN_M) liblinear/liblinear.a  -o $@  $(COMMON_LIBS)	

liblinear : bin/bench_liblinear_mt 

clean-liblinear :
	+$(MAKE) -C liblinear clean

###############################################################################
# PageRank
###############################################################################


gapbs/libpagerank.a :
	+$(MAKE) -C gapbs libpagerank.a

bin/bench_pagerank_mt : gapbs/libpagerank.a
	$(CXX) $(INCLUDES) -DDISABLE_SIGNAL_IN_MAIN $(CFLAGS) -fopenmp \
		$(COMMON_MAIN_M) gapbs/libpagerank.a -o $@  $(COMMON_LIBS)	

pagerank : bin/bench_pagerank_mt 

clean-pagerank :
	+$(MAKE) -C gapbs clean


###############################################################################
# XSBench
###############################################################################

XSBENCHSRC=xsbench/src

$(XSBENCHSRC)/libxsbench.a : 
	+$(MAKE) -C $(XSBENCHSRC) libxsbench.a 

bin/bench_xsbench_mt: $(XSBENCHSRC)/libxsbench.a $(COMMON_MAIN_M)
	$(CC) $(INCLUDES) $(CFLAGS) -fopenmp -DDISABLE_SIGNAL_IN_MAIN \
		$(COMMON_MAIN_M) $(XSBENCHSRC)/libxsbench.a $(COMMON_LIBS) \
		-o $@

bin/bench_xsbench_st: $(XSBENCHSRC)/libxsbench.a $(COMMON_MAIN_S)
	$(CC) $(INCLUDES) $(CFLAGS) -DDISABLE_SIGNAL_IN_MAIN \
		$(COMMON_MAIN_S) $(XSBENCHSRC)/libxsbench.a $(COMMON_LIBS) \
		-o $@	

bin/bench_xsbench_dump: $(XSBENCHSRC)/libxsbench.a $(COMMON_MAIN_D)
	$(CC) $(INCLUDES) $(CFLAGS) -fopenmp -DDISABLE_SIGNAL_IN_MAIN \
		$(COMMON_MAIN_M) $(XSBENCHSRC)/libxsbench.a $(COMMON_LIBS) \
		-o $@

xsbench : bin/bench_xsbench_mt bin/bench_xsbench_dump

clean-xsbench :
	+$(MAKE) -C $(XSBENCHSRC) clean


###############################################################################
# Memops
###############################################################################

bin/bench_memops :
	+$(MAKE) -C memops bench_memops
	cp memops/bench_memops bin

memops: bin/bench_memops 
	
clean-memops :
	+$(MAKE) -C memops clean


###############################################################################
# Stream
###############################################################################

bin/bench_stream :
	+$(MAKE) -C stream stream
	cp stream/stream bin/bench_stream

bin/bench_stream_numa :
	+$(MAKE) -C stream stream_numa
	cp stream/stream_numa bin/bench_stream_numa	

stream: bin/bench_stream bin/bench_stream_numa 

clean-stream :
	+$(MAKE) -C stream clean

###############################################################################
# Clean
###############################################################################

clean: clean-all
	rm -rf bin/*
