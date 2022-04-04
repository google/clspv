// RUN: clspv %s -o %t.spv -uniform-workgroup-size
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int4* a, global float2* b)
{
  *a = *((global int4*)b);
}
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpAccessChain
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[b:%[a-zA-Z0-9_]+]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]] [[_23]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[b]] [[_uint_0]] [[_uint_1]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]] [[_25]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_24]] [[_26]] 0 1 2 3
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpBitcast [[_v4uint]] [[_27]]
