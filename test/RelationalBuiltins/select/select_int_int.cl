// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK:     %[[__original_id_18:[0-9]+]] = OpLoad %[[uint]]
// CHECK:     %[[__original_id_19:[0-9]+]] = OpLoad %[[uint]]
// CHECK:     %[[__original_id_20:[0-9]+]] = OpLoad %[[uint]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_20]] %[[uint_0]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpSelect %[[uint]] %[[__original_id_21]] %[[__original_id_18]] %[[__original_id_19]]
// CHECK:     OpStore {{.*}} %[[__original_id_22]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global int* b, global int* c)
{
    *a = select(*a, *b, *c);
}

