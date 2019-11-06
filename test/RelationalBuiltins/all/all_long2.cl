// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v2bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 2
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_18:[0-9]+]] = OpConstantNull %[[v2ulong]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpLoad %[[v2ulong]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpSLessThan %[[v2bool]] %[[__original_id_25]] %[[__original_id_18]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpAll %[[bool]] %[[__original_id_26]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpSelect %[[uint]] %[[__original_id_27]] %[[uint_1]] %[[uint_0]]
// CHECK:     OpStore {{.*}} %[[__original_id_28]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global long2* b)
{
    *a = all(*b);
}

