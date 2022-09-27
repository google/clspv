// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1

// CHECK: %[[ADDR_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} {{.*}} %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]] %[[ADDR_ID]]
// CHECK: %[[BITCAST0_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[UINT_TYPE_ID]] %[[LOAD_ID]]
// CHECK: %[[ADDR_ID:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} {{.*}} %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_1_ID]]
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]] %[[ADDR_ID]]
// CHECK: %[[BITCAST1_ID:[a-zA-Z0-9_]*]] = OpBitcast %[[UINT_TYPE_ID]] %[[LOAD_ID]]
// CHECK: %[[LO_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT2_TYPE_ID]] {{.*}} UnpackHalf2x16 %[[BITCAST0_ID]]
// CHECK: %[[HI_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT2_TYPE_ID]] {{.*}} UnpackHalf2x16 %[[BITCAST1_ID]]
// CHECK: %[[RECOMBINE_ID:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[FLOAT4_TYPE_ID]] %[[LO_ID]] %[[HI_ID]] 0 1 2 3

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b)
{
  *a = vload_half4(0, (global half *)b);
}
