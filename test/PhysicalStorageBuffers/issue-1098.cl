// RUN: clspv -cl-std=CL3.0 -inline-entry-points -cl-single-precision-constant  -cl-kernel-arg-info   -fp16=0  -rewrite-packed-structs  -std430-ubo-layout  -decorate-nonuniform    -arch=spir64  -physical-storage-buffers  --use-native-builtins=acos,acosh,acospi,asin,asinh,asinpi,atan,atan2,atan2pi,atanh,atanpi,ceil,copysign,fabs,fdim,floor,fma,fmax,fmin,frexp,half_rsqrt,half_sqrt,isequal,isfinite,isgreater,isgreaterequal,isinf,isless,islessequal,islessgreater,isnan,isnormal,isnotequal,isordered,isunordered,ldexp,mad,rint,round,rsqrt,signbit,sqrt,tanh,trunc,  -spv-version=1.6  -max-pushconstant-size=256  -max-ubo-size=65536  -global-offset  -long-vector  -module-constants-in-storage-buffer  -cl-arm-non-uniform-work-group-size  -enable-feature-macros=__opencl_c_images,__opencl_c_read_write_images,__opencl_c_3d_image_writes,__opencl_c_atomic_order_acq_rel,__opencl_c_atomic_scope_device,__opencl_c_subgroups,__opencl_c_int64,__opencl_c_fp64 %s -o %t.spv
// RUN: spirv-val --target-env spv1.6 %t.spv

void test_function_to_call(__global int *output, __global int *input,
                           int where);

__kernel void test_kernel_to_call(__global int *output, __global int *input,
                                  int where) {
  int b;
  if (where == 0) {
    output[get_global_id(0)] = 0;
  }
  for (b = 0; b < where; b++)
    output[get_global_id(0)] += input[b];
}

__kernel void test_call_kernel(__global int *src, __global int *dst,
                               int times) {
  int tid = get_global_id(0);
  int a;
  dst[tid] = 1;
  for (a = 0; a < times; a++)
    test_kernel_to_call(dst, src, tid);
}
void test_function_to_call(__global int *output, __global int *input,
                           int where) {
  int b;
  if (where == 0) {
    output[get_global_id(0)] = 0;
  }
  for (b = 0; b < where; b++)
    output[get_global_id(0)] += input[b];
}

__kernel void test_call_function(__global int *src, __global int *dst,
                                 int times) {
  int tid = get_global_id(0);
  int a;
  dst[tid] = 1;
  for (a = 0; a < times; a++)
    test_function_to_call(dst, src, tid);
}
