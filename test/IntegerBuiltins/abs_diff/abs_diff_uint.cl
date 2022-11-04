// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK:     %[[__original_id_20:[0-9]+]] = OpISub %[[uint]] %[[__original_id_18:[0-9]+]] %[[__original_id_19:[0-9]+]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpISub %[[uint]] %[[__original_id_19]] %[[__original_id_18]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpUGreaterThan %[[bool]] %[[__original_id_19]] %[[__original_id_18]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpSelect %[[uint]] %[[__original_id_22]] %[[__original_id_21]] %[[__original_id_20]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, global uint* b, global uint* c)
{
    *a = abs_diff(*b, *c);
}

