// RUN: clspv %target -verify %s -w
// expected-no-diagnostics

struct T {
  global int* ptr;
};

void bar(struct T* t) {
  *t->ptr = 42;
}

kernel void foo(global int* out) {
  struct T t;
  t.ptr = out;
  bar(&t);
}
