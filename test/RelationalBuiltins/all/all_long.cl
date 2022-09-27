// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[ulong_63:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 63
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[ulong]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpShiftRightLogical %[[ulong]] %[[__original_id_21]] %[[ulong_63]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpUConvert %[[uint]] %[[__original_id_22]]
// CHECK:     OpStore {{.*}} %[[__original_id_23]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global long* b)
{
    *a = all(*b);
}

