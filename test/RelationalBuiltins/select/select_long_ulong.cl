// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[ulong_0:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 0
// CHECK:     %[[__original_id_20:[0-9]+]] = OpLoad %[[ulong]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[ulong]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[ulong]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_22]] %[[ulong_0]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpSelect %[[ulong]] %[[__original_id_23]] %[[__original_id_20]] %[[__original_id_21]]
// CHECK:     OpStore {{.*}} %[[__original_id_24]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global long* a, global long* b, global ulong* c)
{
    *a = select(*a, *b, *c);
}

