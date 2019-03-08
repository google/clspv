// RUN: clspv %s -o %t.spv -int8
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global char3* a, global char3* b) {
  *a = popcount(*b);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char3:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 3
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[char3]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[char3]] [[ld]]
// CHECK: OpStore {{.*}} [[cnt]]
