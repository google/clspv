// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, global float* b)
{
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpConvertUToF %[[FLOAT_TYPE_ID]] %[[LOAD_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]
  *b = (float)*a;
}
