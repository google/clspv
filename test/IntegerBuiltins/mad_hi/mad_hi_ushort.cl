// RUN: clspv -int8 %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_struct_9:[0-9a-zA-Z_]+]] = OpTypeStruct %[[ushort]] %[[ushort]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[ushort_7:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 7
// CHECK-DAG: %[[ushort_42:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 42
// CHECK-DAG: %[[ushort_3:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 3
// CHECK:     %[[__original_id_18:[0-9]+]] = OpUMulExtended %[[_struct_9]] %[[ushort_7]] %[[ushort_42]]
// CHECK:     %[[__original_id_19:[0-9]+]] = OpCompositeExtract %[[ushort]] %[[__original_id_18]] 1
// CHECK:     %[[__original_id_20:[0-9]+]] = OpIAdd %[[ushort]] %[[__original_id_19]] %[[ushort_3]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort* a)
{
    *a = mad_hi((ushort)7, (ushort)42, (ushort)3);
}

