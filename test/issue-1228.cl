// RUN: clspv -inline-entry-points -g -O0 %s -o %t.spv 

typedef struct Baz {
    float x;
} Baz;

static int foo(Baz baz) {
	return 1;
}

__kernel void test(__global Baz *baz) {
    foo(baz[0]);
}
