// RUN: clspv  %s -o %t.spv -int8 -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -vec3-to-vec4 --enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uchar3* a, global uchar3* b, global uchar3* c)
{
    *a = min(*b, *c);
}

// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char4:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 4
// CHECK: [[ld_b:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[ld_c:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[min:%[a-zA-Z0-9_]+]] = OpExtInst [[char4]] {{.*}} UMin [[ld_b]] [[ld_c]]
// CHECK: OpStore {{.*}} [[min]]


