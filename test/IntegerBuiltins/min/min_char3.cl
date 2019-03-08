// RUN: clspv  %s -S -o %t.spvasm -int8
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global char3* a, global char3* b, global char3* c)
{
    *a = min(*b, *c);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char3:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 3
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char3]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char3]]
// CHECK: [[min:%[a-zA-Z0-9_]+]] = OpExtInst [[char3]] {{.*}} SMin [[ld_b]] [[ld_c]]
// CHECK: OpStore {{.*}} [[min]]

