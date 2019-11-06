// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v2float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 2
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v2bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 2
// CHECK-DAG: %[[__original_id_18:[0-9]+]] = OpConstantNull %[[v2uint]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpLoad %[[v2float]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpLoad %[[v2float]]
// CHECK:     %[[__original_id_29:[0-9]+]] = OpLoad %[[v2uint]]
// CHECK:     %[[__original_id_30:[0-9]+]] = OpSLessThan %[[v2bool]] %[[__original_id_29]] %[[__original_id_18]]
// CHECK:     %[[__original_id_31:[0-9]+]] = OpSelect %[[v2float]] %[[__original_id_30]] %[[__original_id_28]] %[[__original_id_27]]
// CHECK:     OpStore {{.*}} %[[__original_id_31]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a, global float2* b, global uint2* c)
{
    *a = select(*a, *b, *c);
}

