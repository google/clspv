// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK-DAG: %[[ushort_65535:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 65535
// CHECK-DAG: %[[__original_id_12:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[ushort_65535]] %[[ushort_65535]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[v2ushort]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v2ushort]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[v2ushort]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpBitwiseXor %[[v2ushort]] %[[__original_id_23]] %[[__original_id_12]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpBitwiseAnd %[[v2ushort]] %[[__original_id_21]] %[[__original_id_24]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpBitwiseAnd %[[v2ushort]] %[[__original_id_23]] %[[__original_id_22]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpBitwiseOr %[[v2ushort]] %[[__original_id_25]] %[[__original_id_26]]
// CHECK:     OpStore {{.*}} %[[__original_id_27]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short2* a, global short2* b, global short2* c)
{
    *a = bitselect(*a, *b, *c);
}

