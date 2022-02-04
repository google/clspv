// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global short3* a, global short3* b) {
  *a = popcount(*b);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[int3:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 3
// CHECK: [[short:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
// CHECK: [[short3:%[a-zA-Z0-9_]+]] = OpTypeVector [[short]] 3
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[short3]]
// CHECK: [[convert:%[a-zA-Z0-9_]+]] = OpUConvert [[int3]] [[ld]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[int3]] [[convert]]
// CHECK: [[res:%[a-zA-Z0-9_]+]] = OpUConvert [[short3]] [[cnt]]
// CHECK: OpStore {{.*}} [[res]]
