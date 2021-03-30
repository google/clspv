// RUN: clspv -cl-std=CL3.0 -fp64=0 %s -verify

#ifdef cl_khr_fp64
#error FAIL
#endif

#ifdef __opencl_c_fp64
#error FAIL
#endif
//expected-no-diagnostics
