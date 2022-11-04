// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v2bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 2
// CHECK-DAG: %[[__original_id_13:[0-9]+]] = OpConstantNull %[[v2ulong]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v2ulong]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[v2ulong]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpLoad %[[v2ulong]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpSLessThan %[[v2bool]] %[[__original_id_24]] %[[__original_id_13]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpSelect %[[v2ulong]] %[[__original_id_25]] %[[__original_id_23]] %[[__original_id_22]]
// CHECK:     OpStore {{.*}} %[[__original_id_26]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ulong2* a, global ulong2* b, global ulong2* c)
{
    *a = select(*a, *b, *c);
}

