// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global ulong* a, global ulong* b) {
  *a = popcount(*b);
}

// CHECK: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[long]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[long]] [[ld]]
// CHECK: OpStore {{.*}} [[cnt]]
