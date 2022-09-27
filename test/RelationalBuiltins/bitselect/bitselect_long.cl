// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[ulong_18446744073709551615:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 18446744073709551615
// CHECK:     %[[__original_id_19:[0-9]+]] = OpLoad %[[ulong]]
// CHECK:     %[[__original_id_20:[0-9]+]] = OpLoad %[[ulong]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[ulong]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpBitwiseXor %[[ulong]] %[[__original_id_21]] %[[ulong_18446744073709551615]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpBitwiseAnd %[[ulong]] %[[__original_id_19]] %[[__original_id_22]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpBitwiseAnd %[[ulong]] %[[__original_id_21]] %[[__original_id_20]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpBitwiseOr %[[ulong]] %[[__original_id_23]] %[[__original_id_24]]
// CHECK:     OpStore {{.*}} %[[__original_id_25]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global long* a, global long* b, global long* c)
{
    *a = bitselect(*a, *b, *c);
}

