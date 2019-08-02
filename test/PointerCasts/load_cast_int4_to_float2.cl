// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int4* a, global float2* b, int i)
{
  *b = ((global float2*)a)[i];
}
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK:  [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpShiftRightLogical [[_uint]] [[_29]] [[_uint_1]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} {{.*}} [[_uint_0]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_v4uint]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_29]] [[_uint_1]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_33]] [[_uint_1]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_uint]] [[_32]] [[_34]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_34]] [[_uint_1]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_uint]] [[_32]] [[_37]]
// CHECK:  [[construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_35]] [[_38]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpBitcast [[_v2float]] [[construct]]
