// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v4ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v4bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 4
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_18:[0-9]+]] = OpConstantNull %[[v4ushort]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpLoad %[[v4ushort]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpSLessThan %[[v4bool]] %[[__original_id_25]] %[[__original_id_18]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpAny %[[bool]] %[[__original_id_26]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpSelect %[[uint]] %[[__original_id_27]] %[[uint_1]] %[[uint_0]]
// CHECK:     OpStore {{.*}} %[[__original_id_28]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global short4* b)
{
    *a = any(*b);
}

