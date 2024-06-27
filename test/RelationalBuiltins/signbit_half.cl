// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[USHORT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 16 0
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[CONSTANT_15_ID:[a-zA-Z0-9_]*]] = OpConstant %[[USHORT_TYPE_ID]] 15
// CHECK: %[[B_BITCAST_ID:[a-zA-Z0-9_]*]] = OpLoad %[[USHORT_TYPE_ID]]
// CHECK: %[[LSHR_ID:[a-zA-Z0-9_]*]] = OpShiftRightLogical %[[USHORT_TYPE_ID]] %[[B_BITCAST_ID]] %[[CONSTANT_15_ID]]
// CHECK: %[[CONV_ID:[a-zA-Z0-9]*]] = OpUConvert %[[UINT_TYPE_ID]] %[[LSHR_ID]]
// CHECK: OpStore {{.*}} %[[CONV_ID]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

void kernel foo(global int* a, global half* b)
{
  *a = signbit(b[0]);
}
