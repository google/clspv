// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global ulong4* a, global ulong4* b) {
  *a = popcount(*b);
}

// CHECK: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[long4:%[a-zA-Z0-9_]+]] = OpTypeVector [[long]] 4
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[long4]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[long4]] [[ld]]
// CHECK: OpStore {{.*}} [[cnt]]
