// RUN: clspv %target -cl-std=CL3.0 --inline-entry-points %s -verify

#ifdef __opencl_c_pipes
#error FAIL
#endif

#ifdef __opencl_c_generic_address_space
#error FAIL
#endif

#ifdef __opencl_c_device_enqueue
#error FAIL
#endif

#ifdef __opencl_c_program_scope_global_variables
#error FAIL
#endif

//expected-no-diagnostics
