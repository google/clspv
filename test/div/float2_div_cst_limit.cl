// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[VEC_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK-DAG: %[[CONSTANT_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 5.64921898e+36
// CHECK-DAG: %[[CONSTANT2_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0.0625
// CHECK-DAG: %[[CONSTANT3_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 42
// CHECK-DAG: %[[CONSTANT4_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 1
// CHECK-DAG: %[[COMPOSITE_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[VEC_TYPE_ID]] %[[CONSTANT_ID]] %[[CONSTANT3_ID]]
// CHECK-DAG: %[[COMPOSITE2_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[VEC_TYPE_ID]] %[[CONSTANT2_ID]] %[[CONSTANT4_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a)
{
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[VEC_TYPE_ID]]
// CHECK: %[[DIV_ID:[a-zA-Z0-9_]*]] = OpFDiv %[[VEC_TYPE_ID]] %[[LOADA_ID]] %[[COMPOSITE_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpFMul %[[VEC_TYPE_ID]] %[[DIV_ID]] %[[COMPOSITE2_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]
    *a /= (float2)(0x1.1p+126, 42.0f);
}
