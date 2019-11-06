// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK-DAG: %[[ulong_18446744073709551615:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 18446744073709551615
// CHECK-DAG: %[[__original_id_12:[0-9]+]] = OpConstantComposite %[[v2ulong]] %[[ulong_18446744073709551615]] %[[ulong_18446744073709551615]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[v2ulong]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v2ulong]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[v2ulong]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpBitwiseXor %[[v2ulong]] %[[__original_id_23]] %[[__original_id_12]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpBitwiseAnd %[[v2ulong]] %[[__original_id_21]] %[[__original_id_24]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpBitwiseAnd %[[v2ulong]] %[[__original_id_23]] %[[__original_id_22]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpBitwiseOr %[[v2ulong]] %[[__original_id_25]] %[[__original_id_26]]
// CHECK:     OpStore {{.*}} %[[__original_id_27]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global long2* a, global long2* b, global long2* c)
{
    *a = bitselect(*a, *b, *c);
}

