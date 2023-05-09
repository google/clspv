// RUN: clspv %s --cl-std=CL3.0 --inline-entry-points -enable-feature-macros=__opencl_c_generic_address_space -o %t.spv --use-native-builtins=frexp
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val --target-env spv1.0 %t.spv
// RUN: FileCheck %s < %t.spvasm

// CHECK: Frexp

__kernel void foo(__global float *out1, __global int *out2, __global float *in) {
    size_t i = get_global_id(0);
    out1[i] = frexp(in[i], out2 + i);
}
