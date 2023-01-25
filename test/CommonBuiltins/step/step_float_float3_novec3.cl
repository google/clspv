// RUN: clspv %target  %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v4float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 4
// CHECK-DAG: %[[v3float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 3
// CHECK-DAG: %[[undefv4:[0-9]+]] = OpUndef %[[v4float]]
// CHECK-DAG: %[[undefv3:[0-9]+]] = OpUndef %[[v3float]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[float]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpLoad %[[v4float]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpCompositeInsert %[[v4float]] %[[__original_id_23]] %[[undefv4]] 0
// CHECK:     %[[__original_id_26:[0-9]+]] = OpVectorShuffle %[[v3float]] %[[__original_id_25]] %[[undefv4]] 0 0 0
// CHECK:     %[[__original_id_24_shuffle:[0-9]+]] = OpVectorShuffle %[[v3float]] %[[__original_id_24]] %[[undefv4]] 0 1 2
// CHECK:     %[[__original_id_27:[0-9]+]] = OpExtInst %[[v3float]] %[[__original_id_1]] Step %[[__original_id_26]] %[[__original_id_24_shuffle]]
// CHECK:     %[[__original_id_27_shuffle:[0-9]+]] = OpVectorShuffle %[[v4float]] %[[__original_id_27]] %[[undefv3]] 0 1 2 4294967295
// CHECK:     OpStore {{.*}} %[[__original_id_27_shuffle]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float3* b)
{
    *b = step(*a, *b);
}

