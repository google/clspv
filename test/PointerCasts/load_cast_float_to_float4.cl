// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float4* b, int i)
{
  *b = ((global float4*)a)[i];
}
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_28]] [[_uint_2]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_29]] [[_uint_1]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a]] [[_uint_0]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_33]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_32]] [[_uint_1]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a]] [[_uint_0]] [[_35]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_35]] [[_uint_1]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a]] [[_uint_0]] [[_38]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_39]]
// CHECK:  [[construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v4float]] [[_31]] [[_34]] [[_37]] [[_40]]
