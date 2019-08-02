// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a, global int4* b, int i)
{
  ((global int4*)a)[i] = *b;
}
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpUndef [[_v4float]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_v4uint]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_29]] [[_uint_1]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpBitcast [[_v4float]] [[_30]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_32]] [[_21]] 0 1
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_32]] [[_21]] 2 3
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_31]]
// CHECK:  OpStore [[_35]] [[_33]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_31]] [[_uint_1]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a]] [[_uint_0]] [[_36]]
// CHECK:  OpStore [[_37]] [[_34]]
