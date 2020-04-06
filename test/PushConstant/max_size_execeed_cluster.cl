// RUN: clspv %s -verify -pod-pushconstant -cluster-pod-kernel-args -max-pushconstant-size=24 -w

kernel void foo(int a, int4 b) {} //expected-error{{max push constant size exceeded}}
