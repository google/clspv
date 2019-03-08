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
// CHECK:     %[[__original_id_17:[0-9]+]] = OpSMulExtended %[[_struct_9]] %[[ushort_7]] %[[ushort_42]]
// CHECK:     OpCompositeExtract %[[ushort]] %[[__original_id_17]] 1


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short* a)
{
    *a = mul_hi((short)7, (short)42);
}

