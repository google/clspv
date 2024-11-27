// RUN: clspv -cl-std=CL3.0 -inline-entry-points -cl-single-precision-constant -cl-kernel-arg-info -rounding-mode-rte=16,32,64 -rewrite-packed-structs -std430-ubo-layout -decorate-nonuniform -arch=spir64 -physical-storage-buffers -cl-arm-integer-dot-product --use-native-builtins=acos,acosh,acospi,asin,asinh,asinpi,atan,atan2,atan2pi,atanh,atanpi,ceil,copysign,fdim,floor,fma,fmax,fmin,frexp,half_rsqrt,half_sqrt,isequal,isfinite,isgreater,isgreaterequal,isinf,isless,islessequal,islessgreater,isnan,isnormal,isnotequal,isordered,isunordered,ldexp,mad,rint,round,rsqrt,signbit,sqrt,tanh,trunc, -spv-version=1.6 -max-pushconstant-size=256 -max-ubo-size=65536 -global-offset -long-vector -module-constants-in-storage-buffer -cl-arm-non-uniform-work-group-size -enable-feature-macros=__opencl_c_images,__opencl_c_3d_image_writes,__opencl_c_read_write_images,__opencl_c_atomic_order_acq_rel,__opencl_c_atomic_scope_device,__opencl_c_subgroups,__opencl_c_int64,__opencl_c_fp64,__opencl_c_integer_dot_product_input_4x8bit,__opencl_c_integer_dot_product_input_4x8bit_packed -enable-printf -printf-buffer-size=1048576 %s -o %t.spv
// RUN: spirv-val --target-env spv1.6 %t.spv

typedef struct myUnpackedStruct {
  char c;
  char8 vec;
} testStruct;

__kernel void test_vec_align_struct(__constant char8 *source,
                                    __global uint *dest) {
  __local testStruct test;
  int tid = get_global_id(0);
  dest[tid] = (uint)((__local uchar *)&(test.vec));
}
