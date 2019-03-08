// RUN: clspv -int8 %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v4ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 4
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_struct_10:[0-9a-zA-Z_]+]] = OpTypeStruct %[[v4ulong]] %[[v4ulong]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[ulong_7:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 7
// CHECK-DAG: %[[__original_id_13:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_7]] %[[ulong_7]] %[[ulong_7]] %[[ulong_7]]
// CHECK-DAG: %[[ulong_42:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 42
// CHECK-DAG: %[[__original_id_15:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_42]] %[[ulong_42]] %[[ulong_42]] %[[ulong_42]]
// CHECK-DAG: %[[ulong_3:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 3
// CHECK-DAG: %[[__original_id_17:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_3]] %[[ulong_3]] %[[ulong_3]] %[[ulong_3]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpSMulExtended %[[_struct_10]] %[[__original_id_13]] %[[__original_id_15]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpCompositeExtract %[[v4ulong]] %[[__original_id_22]] 1
// CHECK:     %[[__original_id_24:[0-9]+]] = OpIAdd %[[v4ulong]] %[[__original_id_23]] %[[__original_id_17]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global long4* a)
{
    *a = mad_hi((long4)7, (long4)42, (long4)3);
}

