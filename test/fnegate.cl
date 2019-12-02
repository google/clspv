// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float* in, global float* out) {
  *out = -(*in);
}

// CHECK: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[float]]
// CHECK: [[neg:%[a-zA-Z0-9_]+]] = OpFNegate [[float]] [[ld]]
// CHECK: OpStore {{.*}} [[neg]]
