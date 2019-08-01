// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

constant uint b = 42;

// CHECK: OpStore {{.*}} %[[CONSTANT_42_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a)
{
  *a = b;
}
