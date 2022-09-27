// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v2bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 2
// CHECK-DAG: %[[__original_id_12:[0-9]+]] = OpConstantNull %[[v2uint]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[v2uint]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v2uint]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[v2uint]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpSLessThan %[[v2bool]] %[[__original_id_23]] %[[__original_id_12]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpSelect %[[v2uint]] %[[__original_id_24]] %[[__original_id_22]] %[[__original_id_21]]
// CHECK:     OpStore {{.*}} %[[__original_id_25]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int2* a, global int2* b, global int2* c)
{
    *a = select(*a, *b, *c);
}

