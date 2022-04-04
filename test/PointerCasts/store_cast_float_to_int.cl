// RUN: clspv %s -o %t.spv -uniform-workgroup-size
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global int* b, int i)
{
  ((global int*)a)[i] = *b;
}
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpBitcast [[_float]] [[_24]]
// CHECK:  OpStore {{.*}} [[_25]]
