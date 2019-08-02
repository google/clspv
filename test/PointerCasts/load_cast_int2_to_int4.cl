// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int2* a, global int4* b, int i)
{
  *b = ((global int4*)a)[i];
}
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_26]] [[_uint_1]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_27]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_28]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_27]] [[_uint_1]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[a]] [[_uint_0]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4uint]] [[_29]] [[_32]] 0 1 2 3
