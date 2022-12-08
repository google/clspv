// RUN: clspv %target %s -o %t.spv -cl-std=CL2.0 -inline-entry-points
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

bool isFenceValid(cl_mem_fence_flags fence) {
    if ((fence == 0) || (fence == CLK_GLOBAL_MEM_FENCE) || (fence == CLK_LOCAL_MEM_FENCE) 
        || (fence == (CLK_GLOBAL_MEM_FENCE | CLK_LOCAL_MEM_FENCE)))
        return true;
    else
        return false;
}


bool helperFunction(float *floatp, float val) {
    if (!isFenceValid(get_fence(floatp)))
        return false;

    if (*floatp != val)
        return false;

    return true;
}

__kernel void testKernel(__global uint *results) {
    uint tid = get_global_id(0);

    __private float val;
    val = 0.1f;
    float * volatile ptr = &val;

    results[tid] = helperFunction(ptr, val);
}

// CHECK-NOT: store volatile float addrspace(4)* {{.*}}, float addrspace(4)** {{.*}}, align 4
// CHECK-NOT: {{.*}} = load volatile float addrspace(4)*, float addrspace(4)** {{.*}}, align 4
