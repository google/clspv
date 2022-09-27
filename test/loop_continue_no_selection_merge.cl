// RUN: clspv %target  %s -o %t.spv --enable-pre=1 --enable-load-pre=1
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpControlBarrier
// CHECK: [[LOOP:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: OpLoopMerge [[MERGE:%[a-zA-Z0-9_]+]] [[CONT:%[a-zA-Z0-9_]+]] None
// CHECK-NEXT: OpBranchConditional {{%[a-zA-Z0-9_]+}} [[TRUE:%[a-zA-Z0-9_]+]] [[CONT]]
// CHECK: [[TRUE]] = OpLabel
// CHECK-NOT: OpLabel
// CHECK: OpBranch [[CONT]]
// CHECK: [[CONT]] = OpLabel
// CHECK-NOT: OpLabel
// CHECK: OpControlBarrier
// CHECK-NOT: OpLabel
// CHECK: OpBranchConditional {{.*}} [[MERGE]] [[LOOP]]

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


