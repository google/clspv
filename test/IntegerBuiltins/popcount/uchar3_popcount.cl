// RUN: clspv %s -o %t.spv -int8
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uchar3* a, global uchar3* b) {
  *a = popcount(*b);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[int3:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 3
// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char3:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 3
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[char3]]
// CHECK: [[convert:%[a-zA-Z0-9_]+]] = OpUConvert [[int3]] [[ld]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[int3]] [[convert]]
// CHECK: [[res:%[a-zA-Z0-9_]+]] = OpUConvert [[char3]] [[cnt]]
// CHECK: OpStore {{.*}} [[res]]
