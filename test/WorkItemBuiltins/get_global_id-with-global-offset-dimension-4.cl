// RUN: clspv -global-offset %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK:     OpStore {{.*}} %[[uint_0]]

void kernel __attribute__((reqd_work_group_size(1,1,1))) test(global int *out) {
    out[0] = get_global_id(3);
}

