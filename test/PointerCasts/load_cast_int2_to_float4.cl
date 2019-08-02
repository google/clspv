// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int2* a, global float4* b, int i)
{
  *b = ((global float4*)a)[i];
}
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_28]] [[_uint_1]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_29]] [[_uint_1]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a]] [[_uint_0]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_33]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4uint]] [[_31]] [[_34]] 0 1 2 3
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpBitcast [[_v4float]] [[_35]]
