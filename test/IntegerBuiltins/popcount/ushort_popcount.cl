// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global ushort* a, global ushort* b) {
  *a = popcount(*b);
}

// CHECK: [[short:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[short]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[short]] [[ld]]
// CHECK: OpStore {{.*}} [[cnt]]
