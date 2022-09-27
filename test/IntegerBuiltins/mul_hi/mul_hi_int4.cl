// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[_struct_9:[0-9a-zA-Z_]+]] = OpTypeStruct %[[v4uint]] %[[v4uint]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_7:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 7
// CHECK-DAG: %[[__original_id_12:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_7]] %[[uint_7]] %[[uint_7]] %[[uint_7]]
// CHECK-DAG: %[[uint_42:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK-DAG: %[[__original_id_14:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_42]] %[[uint_42]] %[[uint_42]] %[[uint_42]]
// CHECK:     %[[__original_id_19:[0-9]+]] = OpSMulExtended %[[_struct_9]] %[[__original_id_12]] %[[__original_id_14]]
// CHECK:     OpCompositeExtract %[[v4uint]] %[[__original_id_19]] 1


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int4* a)
{
    *a = mul_hi((int4)7, (int4)42);
}

