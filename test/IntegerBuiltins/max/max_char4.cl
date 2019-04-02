// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global char4* a, global char4* b, global char4* c) {
  *a = max(*b, *c);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char4:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 4
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[max:%[a-zA-Z0-9_]+]] = OpExtInst [[char4]] {{.*}} SMax [[ld_b]] [[ld_c]]

