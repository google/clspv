// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v3bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 3
// CHECK-DAG: %[[__original_id_12:[0-9]+]] = OpConstantNull %[[v3uint]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[v3uint]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v3uint]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[v3uint]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpSLessThan %[[v3bool]] %[[__original_id_23]] %[[__original_id_12]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpSelect %[[v3uint]] %[[__original_id_24]] %[[__original_id_22]] %[[__original_id_21]]
// CHECK:     OpStore {{.*}} %[[__original_id_25]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint3* a, global uint3* b, global uint3* c)
{
    *a = select(*a, *b, *c);
}

