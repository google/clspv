// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global int* b, int i)
{
  *b = ((global int*)a)[i];
}
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpLoad [[_float]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpBitcast [[_uint]] [[_25]]
