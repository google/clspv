// RUN: clspv %target %s -o %t.spv -int8
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uchar2* a, global uchar2* b) {
  *a = popcount(*b);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char2:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 2
// CHECK: [[int2:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 2
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[char2]]
// CHECK: [[convert:%[a-zA-Z0-9_]+]] = OpUConvert [[int2]] [[ld]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[int2]] [[convert]]
// CHECK: [[res:%[a-zA-Z0-9_]+]] = OpUConvert [[char2]] [[cnt]]
// CHECK: OpStore {{.*}} [[res]]
