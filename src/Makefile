GCC=gcc
CFLAGS=-fpic -shared -march=native -Os -fopenmp -fopenmp-simd
LDFLAGS=-lgomp
OUT=analysis.so

all:
	$(GCC) analysis.c $(CFLAGS) $(LDFLAGS) -o $(OUT)

clean:
	rm -f $(OUT)
