// RUN: clspv  %s -S -o %t.spvasm -int8
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global char* a, global char* b, global char* c) {
  *a = max(*b, *c);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char]]
// CHECK: [[max:%[a-zA-Z0-9_]+]] = OpExtInst [[char]] {{.*}} SMax [[ld_b]] [[ld_c]]
