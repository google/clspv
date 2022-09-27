// RUN: clspv %target %s -verify

typedef struct T {
  int* a[2];
} T;

kernel void foo(global T* t) { //expected-error{{structures may not contain pointers}}
  (void)t;
}

