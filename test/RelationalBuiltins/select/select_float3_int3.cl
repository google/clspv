// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v3float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 3
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v3bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 3
// CHECK-DAG: %[[__original_id_18:[0-9]+]] = OpConstantNull %[[v3uint]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpLoad %[[v3float]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpLoad %[[v3float]]
// CHECK:     %[[__original_id_29:[0-9]+]] = OpLoad %[[v3uint]]
// CHECK:     %[[__original_id_30:[0-9]+]] = OpSLessThan %[[v3bool]] %[[__original_id_29]] %[[__original_id_18]]
// CHECK:     %[[__original_id_31:[0-9]+]] = OpSelect %[[v3float]] %[[__original_id_30]] %[[__original_id_28]] %[[__original_id_27]]
// CHECK:     OpStore {{.*}} %[[__original_id_31]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b, global int3* c)
{
    *a = select(*a, *b, *c);
}

