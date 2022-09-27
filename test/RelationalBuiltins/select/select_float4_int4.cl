// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v4float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 4
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v4bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 4
// CHECK-DAG: %[[__original_id_18:[0-9]+]] = OpConstantNull %[[v4uint]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpLoad %[[v4float]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpLoad %[[v4float]]
// CHECK:     %[[__original_id_29:[0-9]+]] = OpLoad %[[v4uint]]
// CHECK:     %[[__original_id_30:[0-9]+]] = OpSLessThan %[[v4bool]] %[[__original_id_29]] %[[__original_id_18]]
// CHECK:     %[[__original_id_31:[0-9]+]] = OpSelect %[[v4float]] %[[__original_id_30]] %[[__original_id_28]] %[[__original_id_27]]
// CHECK:     OpStore {{.*}} %[[__original_id_31]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b, global int4* c)
{
    *a = select(*a, *b, *c);
}

