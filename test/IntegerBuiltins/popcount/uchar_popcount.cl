// RUN: clspv %s -o %t.spv -int8
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uchar* a, global uchar* b) {
  *a = popcount(*b);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[char]]
// CHECK: [[convert:%[a-zA-Z0-9_]+]] = OpUConvert [[int]] [[ld]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[int]] [[convert]]
// CHECK: [[res:%[a-zA-Z0-9_]+]] = OpUConvert [[char]] [[cnt]]
// CHECK: OpStore {{.*}} [[res]]
