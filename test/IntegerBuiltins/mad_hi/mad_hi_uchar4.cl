// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v4uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 4
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_struct_10:[0-9a-zA-Z_]+]] = OpTypeStruct %[[v4uchar]] %[[v4uchar]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uchar_7:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 7
// CHECK-DAG: %[[__original_id_13:[0-9]+]] = OpConstantComposite %[[v4uchar]] %[[uchar_7]] %[[uchar_7]] %[[uchar_7]] %[[uchar_7]]
// CHECK-DAG: %[[uchar_42:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 42
// CHECK-DAG: %[[__original_id_15:[0-9]+]] = OpConstantComposite %[[v4uchar]] %[[uchar_42]] %[[uchar_42]] %[[uchar_42]] %[[uchar_42]]
// CHECK-DAG: %[[uchar_3:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 3
// CHECK-DAG: %[[__original_id_17:[0-9]+]] = OpConstantComposite %[[v4uchar]] %[[uchar_3]] %[[uchar_3]] %[[uchar_3]] %[[uchar_3]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpUMulExtended %[[_struct_10]] %[[__original_id_13]] %[[__original_id_15]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpCompositeExtract %[[v4uchar]] %[[__original_id_22]] 1
// CHECK:     %[[__original_id_24:[0-9]+]] = OpIAdd %[[v4uchar]] %[[__original_id_23]] %[[__original_id_17]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uchar4* a)
{
    *a = mad_hi((uchar4)7, (uchar4)42, (uchar4)3);
}

