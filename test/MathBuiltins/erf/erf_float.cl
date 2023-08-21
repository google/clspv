// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(global float *s) {
    unsigned gid = get_global_id(0);
    s[gid] = erf(s[gid]);
}
