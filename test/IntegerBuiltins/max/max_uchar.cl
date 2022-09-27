// RUN: clspv %target  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uchar* a, global uchar* b, global uchar* c) {
  *a = max(*b, *c);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char]]
// CHECK: [[max:%[a-zA-Z0-9_]+]] = OpExtInst [[char]] {{.*}} UMax [[ld_b]] [[ld_c]]

