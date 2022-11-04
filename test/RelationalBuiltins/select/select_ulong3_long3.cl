// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v3ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 3
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v3bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 3
// CHECK-DAG: %[[__original_id_13:[0-9]+]] = OpConstantNull %[[v3ulong]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v3ulong]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[v3ulong]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpLoad %[[v3ulong]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpSLessThan %[[v3bool]] %[[__original_id_24]] %[[__original_id_13]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpSelect %[[v3ulong]] %[[__original_id_25]] %[[__original_id_23]] %[[__original_id_22]]
// CHECK:     OpStore {{.*}} %[[__original_id_26]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ulong3* a, global ulong3* b, global long3* c)
{
    *a = select(*a, *b, *c);
}

