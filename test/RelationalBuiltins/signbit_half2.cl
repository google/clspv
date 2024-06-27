// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[USHORT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 16 0
// CHECK-DAG: %[[USHORT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[USHORT_TYPE_ID]] 2
// CHECK-DAG: %[[CONSTANT_15_ID:[a-zA-Z0-9_]*]] = OpConstant %[[USHORT_TYPE_ID]] 15
// CHECK: %[[CONSTANT_15_VEC_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[USHORT2_TYPE_ID]] %[[CONSTANT_15_ID]] %[[CONSTANT_15_ID]]
// CHECK: %[[B_BITCAST_ID:[a-zA-Z0-9_]*]] = OpLoad %[[USHORT2_TYPE_ID]]
// CHECK: %[[LSHR_ID:[a-zA-Z0-9_]*]] = OpShiftRightArithmetic %[[USHORT2_TYPE_ID]] %[[B_BITCAST_ID]] %[[CONSTANT_15_VEC_ID]]
// CHECK: OpStore {{.*}} %[[LSHR_ID]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

void kernel foo(global short2* a, global half2* b)
{
  *a = signbit(b[0]);
}
