// RUN: clspv %target %s -verify -cluster-pod-kernel-args -pod-pushconstant -w

struct A {
  int a[4];
};

kernel void foo(struct A a) {} //expected-error{{arrays are not supported in push constants currently}}
