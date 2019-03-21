// RUN: clspv -int8 %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_struct_8:[0-9a-zA-Z_]+]] = OpTypeStruct %[[uint]] %[[uint]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_7:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 7
// CHECK-DAG: %[[uint_42:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK:     %[[__original_id_16:[0-9]+]] = OpUMulExtended %[[_struct_8]] %[[uint_7]] %[[uint_42]]
// CHECK:     OpCompositeExtract %[[uint]] %[[__original_id_16]] 1


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a)
{
    *a = mul_hi((uint)7, (uint)42);
}

