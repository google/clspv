// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a, global float4* b, int i)
{
  *a = ((global float2*)b)[i];
}
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpShiftRightLogical [[_uint]] [[_28]] [[_uint_1]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} {{.*}} [[_uint_0]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_28]] [[_uint_1]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_32]] [[_uint_1]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_31]] [[_33]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_33]] [[_uint_1]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_31]] [[_36]]
// CHECK:  [[construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2float]] [[_34]] [[_37]]
