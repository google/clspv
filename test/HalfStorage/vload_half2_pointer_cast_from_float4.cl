// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT4_TYPE_ID]]
// CHECK: %[[EXTRACT_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOAD_ID]] 0
// CHECK: %[[BITCAST_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[UINT_TYPE_ID]] %[[EXTRACT_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT2_TYPE_ID]] {{.*}} UnpackHalf2x16 %[[BITCAST_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a, global float4* b)
{
  *a = vload_half2(0, (global half *)b);
}
