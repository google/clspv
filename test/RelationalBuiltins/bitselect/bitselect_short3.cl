// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v3ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 3
// CHECK-DAG: %[[ushort_65535:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 65535
// CHECK-DAG: %[[__original_id_12:[0-9]+]] = OpConstantComposite %[[v3ushort]] %[[ushort_65535]] %[[ushort_65535]] %[[ushort_65535]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[v3ushort]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v3ushort]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[v3ushort]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpBitwiseXor %[[v3ushort]] %[[__original_id_23]] %[[__original_id_12]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpBitwiseAnd %[[v3ushort]] %[[__original_id_21]] %[[__original_id_24]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpBitwiseAnd %[[v3ushort]] %[[__original_id_23]] %[[__original_id_22]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpBitwiseOr %[[v3ushort]] %[[__original_id_25]] %[[__original_id_26]]
// CHECK:     OpStore {{.*}} %[[__original_id_27]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short3* a, global short3* b, global short3* c)
{
    *a = bitselect(*a, *b, *c);
}

