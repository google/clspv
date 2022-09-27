// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float2* b)
{
  vstore_half2(*b, 0, (global half *)a);
}
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]]
// CHECK-NEXT:  [[_23:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_22]]
// CHECK-NEXT:  [[_25:%[0-9a-zA-Z_]+]] = OpBitcast [[_float]] [[_23]]
// CHECK-NEXT:  [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} {{.*}} [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK-NEXT:  OpStore [[_24]] [[_25]]
