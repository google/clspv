// RUN: clspv %target %s -long-vector -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv

// CHECK-COUNT-8: %{{[0-9]+}} = OpExtInst %float %{{[0-9]+}} FMax %{{[0-9]+}} %float_0

__kernel void foo(global float8* out, global float8* in1, global float8* in2) {
    size_t i = get_global_id(0);
    out[i] = fdim(in1[i], in2[i]);
}


