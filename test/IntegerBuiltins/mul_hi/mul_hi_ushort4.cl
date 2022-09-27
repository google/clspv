// RUN: clspv %target -int8 %s -o %t.spv
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
// CHECK:     %[[__original_id_20:[0-9]+]] = OpUMulExtended %[[_struct_10]] %[[__original_id_13]] %[[__original_id_15]]
// CHECK:     OpCompositeExtract %[[v4ushort]] %[[__original_id_20]] 1

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort4* a)
{
    *a = mul_hi((ushort4)7, (ushort4)42);
}

