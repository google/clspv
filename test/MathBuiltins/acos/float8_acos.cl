// RUN: clspv %target %s -o %t.spv --long-vector
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-NOT: OpExtInst {{.*}} Acos

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float8* a, constant float8* b)
{
  *a = acos(*b);
}
