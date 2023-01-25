// RUN: clspv %target  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uchar3* a, global char3* b) {
  *a = abs(*b);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char3:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 3
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[char3]]
// CHECK: [[abs:%[a-zA-Z0-9_]+]] = OpExtInst [[char3]] {{.*}} SAbs [[ld]]
// CHECK: OpStore {{.*}} [[abs]]
