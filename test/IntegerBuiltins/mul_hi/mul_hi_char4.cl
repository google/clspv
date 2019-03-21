// RUN: clspv -int8 %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv -int8 %s -o %t.spv
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
// CHECK:     %[[__original_id_20:[0-9]+]] = OpSMulExtended %[[_struct_10]] %[[__original_id_13]] %[[__original_id_15]]
// CHECK:     OpCompositeExtract %[[v4uchar]] %[[__original_id_20]] 1


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global char4* a)
{
    *a = mul_hi((char4)7, (char4)42);
}

