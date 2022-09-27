// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int4* a, global float2* b)
{
  *((global float2*)a) = *b;
}
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpBitcast [[_v2uint]] [[_23]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_24]] 0
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_24]] 1
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_18:%[a-zA-Z0-9_]+]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  OpStore [[_27]] [[_25]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_18]] [[_uint_0]] [[_uint_0]] [[_uint_1]]
// CHECK:  OpStore [[_28]] [[_26]]
