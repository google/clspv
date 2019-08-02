// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float2* b, int i)
{
  ((global float2*)a)[i] = *b;
}
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpShiftRightLogical [[_uint]] [[_27]] [[_uint_1]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_28]] 0
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_28]] 1
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_27]] [[_uint_1]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_32]] [[_uint_1]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_29]] [[_33]]
// CHECK:  OpStore [[_34]] [[_30]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_33]] [[_uint_1]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a]] [[_uint_0]] [[_29]] [[_35]]
// CHECK:  OpStore [[_36]] [[_31]]
