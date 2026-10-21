// RUN: clspv %target -cl-std=CL3.0 %s -verify
// RUN: clspv %target -cl-std=CL3.0 --enable-feature-macros=__opencl_c_ext_fp32_global_atomic_add,__opencl_c_ext_fp32_local_atomic_add -DENABLED_FP32 %s -verify

#ifdef ENABLED_FP32
#ifndef cl_ext_float_atomics
#error cl_ext_float_atomics should be defined
#endif
#ifndef __opencl_c_ext_fp32_global_atomic_add
#error __opencl_c_ext_fp32_global_atomic_add should be defined
#endif
#ifndef __opencl_c_ext_fp32_local_atomic_add
#error __opencl_c_ext_fp32_local_atomic_add should be defined
#endif
#else
#ifdef cl_ext_float_atomics
#error cl_ext_float_atomics should not be defined
#endif
#ifdef __opencl_c_ext_fp32_global_atomic_add
#error __opencl_c_ext_fp32_global_atomic_add should not be defined
#endif
#ifdef __opencl_c_ext_fp32_local_atomic_add
#error __opencl_c_ext_fp32_local_atomic_add should not be defined
#endif
#endif

#ifdef __opencl_c_ext_fp16_global_atomic_add
#error __opencl_c_ext_fp16_global_atomic_add should not be defined
#endif
#ifdef __opencl_c_ext_fp16_local_atomic_add
#error __opencl_c_ext_fp16_local_atomic_add should not be defined
#endif
#ifdef __opencl_c_ext_fp16_global_atomic_load_store
#error __opencl_c_ext_fp16_global_atomic_load_store should not be defined
#endif
#ifdef __opencl_c_ext_fp16_local_atomic_load_store
#error __opencl_c_ext_fp16_local_atomic_load_store should not be defined
#endif
#ifdef __opencl_c_ext_fp16_global_atomic_min_max
#error __opencl_c_ext_fp16_global_atomic_min_max should not be defined
#endif
#ifdef __opencl_c_ext_fp16_local_atomic_min_max
#error __opencl_c_ext_fp16_local_atomic_min_max should not be defined
#endif
#ifdef __opencl_c_ext_fp32_global_atomic_min_max
#error __opencl_c_ext_fp32_global_atomic_min_max should not be defined
#endif
#ifdef __opencl_c_ext_fp32_local_atomic_min_max
#error __opencl_c_ext_fp32_local_atomic_min_max should not be defined
#endif
#ifdef __opencl_c_ext_fp64_global_atomic_add
#error __opencl_c_ext_fp64_global_atomic_add should not be defined
#endif
#ifdef __opencl_c_ext_fp64_local_atomic_add
#error __opencl_c_ext_fp64_local_atomic_add should not be defined
#endif
#ifdef __opencl_c_ext_fp64_global_atomic_min_max
#error __opencl_c_ext_fp64_global_atomic_min_max should not be defined
#endif
#ifdef __opencl_c_ext_fp64_local_atomic_min_max
#error __opencl_c_ext_fp64_local_atomic_min_max should not be defined
#endif

//expected-no-diagnostics
