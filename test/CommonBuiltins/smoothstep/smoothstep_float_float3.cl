// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v3float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 3
// CHECK-DAG: %[[v4float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 4
// CHECK:     %[[__original_id_25:[0-9]+]] = OpLoad %[[float]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpLoad %[[float]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpLoad %[[v4float]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpCompositeInsert %[[v4float]] %[[__original_id_25]] %{{.*}} 0
// CHECK:     %[[__original_id_30:[0-9]+]] = OpCompositeInsert %[[v4float]] %[[__original_id_26]] %{{.*}} 0
// CHECK:     %[[__original_id_29:[0-9]+]] = OpVectorShuffle %[[v3float]] %[[__original_id_28]] %{{.*}} 0 0 0
// CHECK:     %[[__original_id_31:[0-9]+]] = OpVectorShuffle %[[v3float]] %[[__original_id_30]] %{{.*}} 0 0 0
// CHECK:     %[[shufflec:[a-zA-Z0-9]+]] = OpVectorShuffle %[[v3float]] %[[__original_id_27]] %{{.*}} 0 1 2
// CHECK:     %[[__original_id_32:[0-9]+]] = OpExtInst %[[v3float]] %[[__original_id_1]] SmoothStep %[[__original_id_29]] %[[__original_id_31]] %[[shufflec]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float* b, global float3* c)
{
    *c = smoothstep(*a, *b, *c);
}

