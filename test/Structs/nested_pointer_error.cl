// RUN: clspv %s -verify

typedef struct S {
  int* ptr;
} S;

typedef struct T {
  S s;
} T;

kernel void foo(global T* t) { //expected-error{{structures may not contain pointers}}
  (void)t;
}
