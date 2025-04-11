// RUN: clspv %target --long-vector %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-COUNT-8: OpLoad %[[FLOAT_TYPE_ID]]
// CHECK-COUNT-1: OpFunctionCall
// CHECK-COUNT-8: OpStore

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float8* a, global float8* b, global float8* c)
{
  *a = pow(*b, *c);
}
