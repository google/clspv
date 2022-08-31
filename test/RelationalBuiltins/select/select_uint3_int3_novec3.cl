// RUN: clspv  %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -vec3-to-vec4 --enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v4bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 4
// CHECK-DAG: %[[__original_id_12:[0-9]+]] = OpConstantNull %[[v4uint]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[v4uint]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v4uint]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[v4uint]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpSLessThan %[[v4bool]] %[[__original_id_23]] %[[__original_id_12]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpSelect %[[v4uint]] %[[__original_id_24]] %[[__original_id_22]] %[[__original_id_21]]
// CHECK:     OpStore {{.*}} %[[__original_id_25]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint3* a, global uint3* b, global int3* c)
{
    *a = select(*a, *b, *c);
}

