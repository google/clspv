// RUN: clspv %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global ushort3* a, global ushort3* b) {
  *a = popcount(*b);
}

// CHECK: [[short:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
// CHECK: [[short4:%[a-zA-Z0-9_]+]] = OpTypeVector [[short]] 4
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[short4]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[short4]] [[ld]]
// CHECK: OpStore {{.*}} [[cnt]]
