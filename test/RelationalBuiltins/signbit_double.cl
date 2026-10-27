// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[ULONG_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 64 0
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[CONSTANT_63_ID:[a-zA-Z0-9_]*]] = OpConstant %[[ULONG_TYPE_ID]] 63
// CHECK: %[[B_BITCAST_ID:[a-zA-Z0-9_]*]] = OpLoad %[[ULONG_TYPE_ID]]
// CHECK: %[[LSHR_ID:[a-zA-Z0-9_]*]] = OpShiftRightLogical %[[ULONG_TYPE_ID]] %[[B_BITCAST_ID]] %[[CONSTANT_63_ID]]
// CHECK: %[[CONV_ID:[a-zA-Z0-9_]*]] = OpUConvert %[[UINT_TYPE_ID]] %[[LSHR_ID]]
// CHECK: OpStore {{.*}} %[[CONV_ID]]

void kernel foo(global int* a, global double* b)
{
  *a = signbit(b[0]);
}
