// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_4294967295:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967295
// CHECK:     %[[__original_id_17:[0-9]+]] = OpLoad %[[float]]
// CHECK:     %[[__original_id_18:[0-9]+]] = OpBitcast %[[uint]] %[[__original_id_17]]
// CHECK:     %[[__original_id_20:[0-9]+]] = OpLoad %[[float]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpBitcast %[[uint]] %[[__original_id_20]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[float]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpBitcast %[[uint]] %[[__original_id_23]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpBitwiseXor %[[uint]] %[[__original_id_24]] %[[uint_4294967295]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_18]] %[[__original_id_25]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_24]] %[[__original_id_21]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpBitwiseOr %[[uint]] %[[__original_id_26]] %[[__original_id_27]]
// CHECK:     %[[__original_id_29:[0-9]+]] = OpBitcast %[[float]] %[[__original_id_28]]
// CHECK:     OpStore {{.*}} %[[__original_id_29]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float* b, global float* c)
{
    *a = bitselect(*a, *b, *c);
}

