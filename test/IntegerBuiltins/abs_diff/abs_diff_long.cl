// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK:     %[[__original_id_21:[0-9]+]] = OpISub %[[ulong]] %[[__original_id_19:[0-9]+]] %[[__original_id_20:[0-9]+]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpISub %[[ulong]] %[[__original_id_20]] %[[__original_id_19]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpSGreaterThan %[[bool]] %[[__original_id_20]] %[[__original_id_19]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpSelect %[[ulong]] %[[__original_id_23]] %[[__original_id_22]] %[[__original_id_21]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ulong* a, global long* b, global long* c)
{
    *a = abs_diff(*b, *c);
}

