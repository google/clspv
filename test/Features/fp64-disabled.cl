// RUN: clspv %target -fp64=0 %s -verify

#ifdef cl_khr_fp64
#error FAIL
#endif
//expected-no-diagnostics
