// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global ulong2* a, global ulong2* b) {
  *a = popcount(*b);
}

// CHECK: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[long2:%[a-zA-Z0-9_]+]] = OpTypeVector [[long]] 2
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[long2]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[long2]] [[ld]]
// CHECK: OpStore {{.*}} [[cnt]]
