// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_struct_9:[0-9a-zA-Z_]+]] = OpTypeStruct %[[ulong]] %[[ulong]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[ulong_7:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 7
// CHECK-DAG: %[[ulong_42:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 42
// CHECK:     %[[__original_id_17:[0-9]+]] = OpUMulExtended %[[_struct_9]] %[[ulong_7]] %[[ulong_42]]
// CHECK:     OpCompositeExtract %[[ulong]] %[[__original_id_17]] 1


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ulong* a)
{
    *a = mul_hi((ulong)7, (ulong)42);
}

