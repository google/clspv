// RUN: clspv %s --cl-std=CL3.0 --inline-entry-points -enable-feature-macros=__opencl_c_generic_address_space -o %t.spv
// RUN: spirv-val --target-env spv1.0 %t.spv

__kernel void foo(__global float *out1, __global int *out2, __global float *in) {
    size_t i = get_global_id(0);
    out1[i] = remquo(in[i], in[i + 1], out2 + i);
}
