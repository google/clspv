// RUN: clspv -int8 %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v4ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_struct_10:[0-9a-zA-Z_]+]] = OpTypeStruct %[[v4ushort]] %[[v4ushort]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[ushort_7:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 7
// CHECK-DAG: %[[__original_id_13:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[ushort_7]] %[[ushort_7]] %[[ushort_7]] %[[ushort_7]]
// CHECK-DAG: %[[ushort_42:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 42
// CHECK-DAG: %[[__original_id_15:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[ushort_42]] %[[ushort_42]] %[[ushort_42]] %[[ushort_42]]
// CHECK-DAG: %[[ushort_3:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 3
// CHECK-DAG: %[[__original_id_17:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[ushort_3]] %[[ushort_3]] %[[ushort_3]] %[[ushort_3]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpUMulExtended %[[_struct_10]] %[[__original_id_13]] %[[__original_id_15]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpCompositeExtract %[[v4ushort]] %[[__original_id_22]] 1
// CHECK:     %[[__original_id_24:[0-9]+]] = OpIAdd %[[v4ushort]] %[[__original_id_23]] %[[__original_id_17]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort4* a)
{
    *a = mad_hi((ushort4)7, (ushort4)42, (ushort4)3);
}

