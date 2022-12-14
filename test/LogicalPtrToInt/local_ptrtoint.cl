// RUN: clspv %target %s -o %t.spv --hack-logical-ptrtoint
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check virtual addresses 0x1000000000000000, 0x1000100000000000, and
// 0x1000200000000008 are stored.
// CHECK: [[ulong:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[addr_var0:%[a-zA-Z0-9_]+]] = OpConstant [[ulong]] 1152921504606846976
// CHECK: [[addr_var1:%[a-zA-Z0-9_]+]] = OpConstant [[ulong]] 1152939096792891392
// CHECK: [[addr_var2:%[a-zA-Z0-9_]+]] = OpConstant [[ulong]] 1152956688978935816

// CHECK-DAG: OpStore %{{.*}} [[addr_var0]]
// CHECK-DAG: OpStore %{{.*}} [[addr_var1]]
// CHECK-DAG: OpStore %{{.*}} [[addr_var2]]

__kernel void test(__global long *dest_a, __global long *dest_b,
    __global long *dest_c)
{
    size_t gid = get_global_id(0);
    __local uint var0;
    __local uint var1;
    __local uint var2[10];
    
    dest_a[gid] = (long) &var0;
    dest_b[gid] = (long) &var1;
    dest_c[gid] = (long) &(var2[2]);
}
