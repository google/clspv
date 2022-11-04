// RUN: clspv %target -verify %s

struct T;
typedef struct S {
  struct T* pt;  // forward-declared pointer type.
  int a;
} S;

typedef struct T { 
  S* ps;
} T;

kernel void foo(global S* s) { //expected-error{{recursive structures are not supported}}
  s->a = 1;
}

