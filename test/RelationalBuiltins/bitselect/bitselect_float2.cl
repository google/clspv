// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v2float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 2
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[uint_4294967295:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967295
// CHECK-DAG: %[[__original_id_13:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_4294967295]] %[[uint_4294967295]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v2float]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpBitcast %[[v2uint]] %[[__original_id_22]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpLoad %[[v2float]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpBitcast %[[v2uint]] %[[__original_id_24]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpLoad %[[v2float]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpBitcast %[[v2uint]] %[[__original_id_26]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpBitwiseXor %[[v2uint]] %[[__original_id_27]] %[[__original_id_13]]
// CHECK:     %[[__original_id_29:[0-9]+]] = OpBitwiseAnd %[[v2uint]] %[[__original_id_23]] %[[__original_id_28]]
// CHECK:     %[[__original_id_30:[0-9]+]] = OpBitwiseAnd %[[v2uint]] %[[__original_id_27]] %[[__original_id_25]]
// CHECK:     %[[__original_id_31:[0-9]+]] = OpBitwiseOr %[[v2uint]] %[[__original_id_29]] %[[__original_id_30]]
// CHECK:     %[[__original_id_32:[0-9]+]] = OpBitcast %[[v2float]] %[[__original_id_31]]
// CHECK:     OpStore {{.*}} %[[__original_id_32]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a, global float2* b, global float2* c)
{
    *a = bitselect(*a, *b, *c);
}

