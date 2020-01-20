// RUN: clspv -verify %s

struct T {
  global int* ptr;
};

kernel void foo(global struct T* t) { //expected-error{{structures may not contain pointers}}
  *t->ptr = 0;
}
