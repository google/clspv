// RUN: clspv %target %s -o %t.spv --hack-logical-ptrtoint
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: not spirv-val --target-env vulkan1.0 %t.spv

// Check that a virtual address (which would be 0x1000000000000000) is not
// generated. We also expect spitv-val to fail.
// CHECK: [[ulong:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK-NOT: [[addr_var0:%[a-zA-Z0-9_]+]] = OpConstant [[ulong]] 1152921504606846976

__kernel void test(__global long *dest, int offset)
{
    size_t gid = get_global_id(0);
    __local uint var0[10];
    long var0_addr = (long) var0;
    __local long* ptr = (__local long *) (var0_addr + offset);
    dest[gid] = *ptr;
}
