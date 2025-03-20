// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

// CHECK: [[uint_40:%[^ ]+]] = OpConstant {{.*}} 40
// CHECK: [[variable:%[^ ]+]] = OpVariable {{.*}} Workgroup
// CHECK: OpExtInst {{.*}} {{.*}} WorkgroupVariableSize [[variable]] [[uint_40]]

__kernel void local_memory_kernel(global int* data) {
    __local int array[10];

    size_t id = get_global_id(0);
    array[id] = id;

    barrier(CLK_LOCAL_MEM_FENCE);
    data[id] = array[id] + array[id + 1];
}
