// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short* a, global short* b)
{
  *a += *b;
}
// CHECK:  OpCapability Int16
// CHECK:  [[_ushort:%[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK:  [[_16:%[0-9a-zA-Z_]+]] = OpLoad [[_ushort]]
// CHECK:  [[_17:%[0-9a-zA-Z_]+]] = OpLoad [[_ushort]]
// CHECK:  [[_18:%[0-9a-zA-Z_]+]] = OpIAdd [[_ushort]] [[_17]] [[_16]]
// CHECK:  OpStore {{.*}} [[_18]]
