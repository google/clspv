// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global long3* a, global long3* b) {
  *a = popcount(*b);
}

// CHECK: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[long3:%[a-zA-Z0-9_]+]] = OpTypeVector [[long]] 3
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[long3]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[long3]] [[ld]]
// CHECK: OpStore {{.*}} [[cnt]]
