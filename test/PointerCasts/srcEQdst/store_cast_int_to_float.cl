// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global float* b, int i)
{
  ((global float*)a)[i] = *b;
}
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLoad [[_float]]
// CHECK:  OpStore {{.*}} [[_24]]
