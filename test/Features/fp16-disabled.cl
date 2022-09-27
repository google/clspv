// RUN: clspv %target -fp16=0 %s -verify

#ifdef cl_khr_fp16
#error FAIL
#endif
//expected-no-diagnostics
