// RUN: clspv %target -verify %s -w
// expected-no-diagnostics

struct T {
  global int* ptr;
};

struct T bar(global int* out) {
  struct T t;
  t.ptr = out;
  return t;
}

kernel void foo(global int* out) {
  struct T t = bar(out);
  *(t.ptr) = 42;
}
