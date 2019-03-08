// RUN: clspv %s -o %t.spv -int8
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uchar4* a, global uchar4* b) {
  *a = popcount(*b);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char4:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 4
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[char4]] [[ld]]
// CHECK: OpStore {{.*}} [[cnt]]
