// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[ushort_65535:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 65535
// CHECK:     %[[__original_id_19:[0-9]+]] = OpLoad %[[ushort]]
// CHECK:     %[[__original_id_20:[0-9]+]] = OpLoad %[[ushort]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[ushort]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpBitwiseXor %[[ushort]] %[[__original_id_21]] %[[ushort_65535]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpBitwiseAnd %[[ushort]] %[[__original_id_19]] %[[__original_id_22]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpBitwiseAnd %[[ushort]] %[[__original_id_21]] %[[__original_id_20]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpBitwiseOr %[[ushort]] %[[__original_id_23]] %[[__original_id_24]]
// CHECK:     OpStore {{.*}} %[[__original_id_25]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short* a, global short* b, global short* c)
{
    *a = bitselect(*a, *b, *c);
}

