// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[float]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpLoad %[[float]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpLoad %[[uint]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_25]] %[[uint_0]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpSelect %[[float]] %[[__original_id_26]] %[[__original_id_23]] %[[__original_id_24]]
// CHECK:     OpStore {{.*}} %[[__original_id_27]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float* b, global uint* c)
{
    *a = select(*a, *b, *c);
}

