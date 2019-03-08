// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global short3* a, global short3* b) {
  *a = popcount(*b);
}

// CHECK: [[short:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
// CHECK: [[short3:%[a-zA-Z0-9_]+]] = OpTypeVector [[short]] 3
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[short3]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[short3]] [[ld]]
// CHECK: OpStore {{.*}} [[cnt]]
