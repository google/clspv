// RUN: clspv -inline-entry-points -g -O0 %s -o %t.spv 

typedef struct Baz {
    float x;
} Baz;

static void foo(Baz baz) {
}

__kernel void test(__global Baz *baz) {
    foo(baz[0]);
}
