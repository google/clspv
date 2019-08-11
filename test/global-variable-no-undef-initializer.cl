// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[__original_id_29:[0-9]+]] = OpVariable {{.*}} Workgroup
// CHECK-DAG: %[[__original_id_1:[0-9]+]] = OpVariable {{.*}} Workgroup

__kernel void
top_scan(__global uint * isums,
         const int n,
         __local uint * lmem)
{
    __local int s_seed;
    s_seed = 0; barrier(CLK_LOCAL_MEM_FENCE);

    int last_thread = (get_local_id(0) < n &&
                      (get_local_id(0)+1) == n) ? 1 : 0;

    for (int d = 0; d < 16; d++)
    {
        int idx = get_local_id(0);
        lmem[idx] = 0;
        if (last_thread)
        {
            s_seed += 42;
        }
        barrier(CLK_LOCAL_MEM_FENCE);
    }
}

