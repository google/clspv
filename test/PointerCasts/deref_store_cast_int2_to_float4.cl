// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int2* a, global float4* b)
{
  *((global float4*)a) = *b;
}
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_17:%[0-9a-zA-Z_]+]] = OpUndef [[_v4uint]]
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpBitcast [[_v4uint]] [[_24]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2uint]] [[_25]] [[_17]] 0 1
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2uint]] [[_25]] [[_17]] 2 3
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a:%[a-zA-Z0-9_]+]] [[_uint_0]] [[_uint_0]]
// CHECK:  OpStore [[_28]] [[_26]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a:%[a-zA-Z0-9_]+]] [[_uint_0]] [[_uint_1]]
// CHECK:  OpStore [[_29]] [[_27]]
