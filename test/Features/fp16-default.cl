// RUN: clspv %target %s -verify

#ifndef cl_khr_fp16
#error FAIL
#endif
//expected-no-diagnostics
