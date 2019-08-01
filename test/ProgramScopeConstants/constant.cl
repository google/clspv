// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

constant uint b = 42;

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: %[[CONSTANT_42_ID:[a-zA-Z0-9_]+]] = OpConstant [[uint]] 42
// CHECK: OpStore {{.*}} %[[CONSTANT_42_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a)
{
  *a = b;
}
