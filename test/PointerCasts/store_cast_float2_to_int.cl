// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a, global int* b, int i)
{
  ((global int*)a)[i] = *b;
}
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpShiftRightLogical [[_uint]] [[_25]] [[_uint_1]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_25]] [[_uint_1]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} {{.*}} [[_uint_0]] [[_27]] [[_28]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpBitcast [[_float]] [[_26]]
// CHECK:  OpStore [[_29]] [[_30]]
