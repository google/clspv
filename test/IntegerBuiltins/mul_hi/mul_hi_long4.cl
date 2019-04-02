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
// CHECK:     %[[__original_id_20:[0-9]+]] = OpSMulExtended %[[_struct_10]] %[[__original_id_13]] %[[__original_id_15]]
// CHECK:     OpCompositeExtract %[[v4ulong]] %[[__original_id_20]] 1


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global long4* a)
{
    *a = mul_hi((long4)7, (long4)42);
}

