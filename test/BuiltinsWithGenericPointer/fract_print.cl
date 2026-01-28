// RUN: clspv %s --cl-std=CL3.0 --inline-entry-points -enable-feature-macros=__opencl_c_generic_address_space -o %t.spv -print-before-all 2> %t.ll
// RUN: FileCheck %s < %t.ll
// RUN: spirv-val --target-env spv1.0 %t.spv

// CHECK: declare spir_func float @_Z5fractfPU3AS4f(float, ptr addrspace(4))

// CHECK: @clspv.builtins.used = appending global [3 x ptr] [ptr @_Z5fractfPf, ptr @_Z5fractfPU3AS1f, ptr @_Z5fractfPU3AS3f], section "llvm.metadata"
// CHECK-DAG: define {{.*}} float @_Z5fractfPf(
// CHECK-DAG: define {{.*}} float @_Z5fractfPU3AS3f(
// CHECK-DAG: define {{.*}} float @_Z5fractfPU3AS1f(

__kernel void foo(__global float *out1, __global float *out2, __global float *in) {
    size_t i = get_global_id(0);
    out1[i] = fract(in[i], out2 + i);
}
