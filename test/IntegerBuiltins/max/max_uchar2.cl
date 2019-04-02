// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uchar2* a, global uchar2* b, global uchar2* c) {
  *a = max(*b, *c);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char2:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 2
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char2]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char2]]
// CHECK: [[max:%[a-zA-Z0-9_]+]] = OpExtInst [[char2]] {{.*}} UMax [[ld_b]] [[ld_c]]
