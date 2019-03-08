// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global short2* a, global short2* b) {
  *a = popcount(*b);
}

// CHECK: [[short:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
// CHECK: [[short2:%[a-zA-Z0-9_]+]] = OpTypeVector [[short]] 2
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[short2]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[short2]] [[ld]]
// CHECK: OpStore {{.*}} [[cnt]]
