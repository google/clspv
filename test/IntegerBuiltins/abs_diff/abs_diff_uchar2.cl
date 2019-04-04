// RUN: clspv -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v2uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 2
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v2bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 2
// CHECK:     %[[__original_id_23:[0-9]+]] = OpISub %[[v2uchar]] %[[__original_id_21:[0-9]+]] %[[__original_id_22:[0-9]+]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpISub %[[v2uchar]] %[[__original_id_22]] %[[__original_id_21]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpUGreaterThan %[[v2bool]] %[[__original_id_22]] %[[__original_id_21]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpSelect %[[v2uchar]] %[[__original_id_25]] %[[__original_id_24]] %[[__original_id_23]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uchar2* a, global uchar2* b, global uchar2* c)
{
    *a = abs_diff(*b, *c);
}

