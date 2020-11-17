CC = g++
CFLAGS = -x c++ -std=c++11 -O0 -g

OBJS= \
	  src/main.o

.SUFFIXES: .cpp .c .o

.PHONY: all debug_cpp release_cpp clean

all: release_cpp

run: release_cpp
	./clipssweeper

debug_cpp : CC = g++
debug_cpp : CFLAGS = -x c++ -std=c++11 -O0 -g -MD
debug_cpp : LDLIBS = -lstdc++
debug_cpp : clipssweeper

release_cpp : CC = g++
release_cpp : CFLAGS = -x c++ -std=c++11 -O3 -fno-strict-aliasing -MD
release_cpp : LDLIBS = -lstdc++
release_cpp : clipssweeper

.cpp.o :
	$(CC) -c -MD $(CFLAGS) $(WARNINGS) $< -o $@

clipssweeper : src/main.o clips/core/libclips.a
	$(CC) -o clipssweeper src/main.o -L./clips/core -lclips $(LDLIBS)

clips/core/libclips.a:
	cd clips/core && make release_cpp && cd ../..

clean:
	cd clips/core && make clean && cd ../..
	rm -f $(OBJS)

-include $(OBJS:.o=.d)
