// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[CONSTANT_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 5.64921898e+36
// CHECK-DAG: %[[CONSTANT2_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0.0625
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a)
{
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
// CHECK: %[[DIV_ID:[a-zA-Z0-9_]*]] = OpFDiv %[[FLOAT_TYPE_ID]] %[[LOADA_ID]] %[[CONSTANT_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpFMul %[[FLOAT_TYPE_ID]] %[[DIV_ID]] %[[CONSTANT2_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]
  *a /= 0x1.1p+126;
}
