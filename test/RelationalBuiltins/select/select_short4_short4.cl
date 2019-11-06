// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v4ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v4bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 4
// CHECK-DAG: %[[__original_id_13:[0-9]+]] = OpConstantNull %[[v4ushort]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v4ushort]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[v4ushort]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpLoad %[[v4ushort]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpSLessThan %[[v4bool]] %[[__original_id_24]] %[[__original_id_13]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpSelect %[[v4ushort]] %[[__original_id_25]] %[[__original_id_23]] %[[__original_id_22]]
// CHECK:     OpStore {{.*}} %[[__original_id_26]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short4* a, global short4* b, global short4* c)
{
    *a = select(*a, *b, *c);
}

