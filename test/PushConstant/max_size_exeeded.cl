// RUN: clspv %target %s -verify -pod-pushconstant -cluster-pod-kernel-args -max-pushconstant-size=8 -w

kernel void foo(global int* data, int4 pod) { } //expected-error{{max push constant size exceeded}}
