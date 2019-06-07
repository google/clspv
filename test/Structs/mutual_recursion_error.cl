// RUN: clspv -verify %s

struct T;
typedef struct S {
  struct T* pt;  // forward-declared pointer type.
  int a;
} S;

typedef struct T { 
  S* ps;
} T;

kernel void foo(global S* s) { //expected-error{{structures may not contain pointers}}
  s->a = 1;
}

