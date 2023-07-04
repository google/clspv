// RUN: clspv %s -o %t.spv --hack-logical-ptrtoint -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check virtual addresses 0x10000000, 0x20000000, and
// 0x30000008 are stored.
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[addr_var0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 268435456
// CHECK: [[addr_var1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 536870912
// CHECK: [[addr_var2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 805306376

// CHECK-DAG: OpStore %{{.*}} [[addr_var0]]
// CHECK-DAG: OpStore %{{.*}} [[addr_var1]]
// CHECK-DAG: OpStore %{{.*}} [[addr_var2]]

__kernel void test(__global uint *dest_a, __global uint *dest_b,
    __global uint *dest_c)
{
    size_t gid = get_global_id(0);
    __local uint var0;
    __local uint var1;
    __local uint var2[10];
    
    dest_a[gid] = (uint) &var0;
    dest_b[gid] = (uint) &var1;
    dest_c[gid] = (uint) &(var2[2]);
}
