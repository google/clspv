// RUN: clspv %target %s -o %t.spv -cl-std=CL2.0 -inline-entry-points
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK-DAG: [[NO_MEM_FENCE:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[GLOBAL_MEM_FENCE:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[LOCAL_MEM_FENCE:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 1

__kernel void testKernelGlobalFence(__global uint *ptr, __local uint *fence) {
    // CHECK: OpStore {{.*}} [[GLOBAL_MEM_FENCE]]
    *fence = get_fence(ptr);
}

__kernel void testKernelLocalFence(__local uint *ptr, __local uint *fence) {
    // CHECK: OpStore {{.*}} [[LOCAL_MEM_FENCE]]
    *fence = get_fence(ptr);
}

__kernel void testKernelNoFence(__local uint *fence) {
    uint* ptr;
    // CHECK: OpStore {{.*}} [[NO_MEM_FENCE]]
    *fence = get_fence(ptr);
}
