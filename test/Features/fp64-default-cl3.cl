// RUN: clspv %target -cl-std=CL3.0 --inline-entry-points %s -verify

#ifndef cl_khr_fp64
#error FAIL
#endif

#ifndef __opencl_c_fp64
#error FAIL
#endif
//expected-no-diagnostics
