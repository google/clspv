// RUN: clspv %target %s -verify

#ifndef cl_khr_fp64
#error FAIL
#endif
//expected-no-diagnostics
