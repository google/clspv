// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -cl-unsafe-math-optimizations
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck --check-prefix=CHECK-UNSAFE %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpCapability Float16
// CHECK-DAG: %[[HALF_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 16
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[HALF_TYPE_ID]]
// CHECK: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[HALF_TYPE_ID]]
// CHECK: %[[CVTA_ID:[a-zA-Z0-9_]*]] = OpFConvert %[[FLOAT_TYPE_ID]] %[[LOADA_ID]]
// CHECK: %[[CVTB_ID:[a-zA-Z0-9_]*]] = OpFConvert %[[FLOAT_TYPE_ID]] %[[LOADB_ID]]
// CHECK: %[[DIV_ID:[a-zA-Z0-9_]*]] = OpFDiv %[[FLOAT_TYPE_ID]] %[[CVTA_ID]] %[[CVTB_ID]]
// CHECK: %[[CVTDIV_ID:[a-zA-Z0-9_]*]] = OpFConvert %[[HALF_TYPE_ID]] %[[DIV_ID]]
// CHECK: OpStore {{.*}} %[[CVTDIV_ID]]

// CHECK-UNSAFE: OpCapability Float16
// CHECK-UNSAFE-DAG: %[[HALF_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 16
// CHECK-UNSAFE: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[HALF_TYPE_ID]]
// CHECK-UNSAFE: %[[LOADA_ID:[a-zA-Z0-9_]*]] = OpLoad %[[HALF_TYPE_ID]]
// CHECK-UNSAFE: %[[DIV_ID:[a-zA-Z0-9_]*]] = OpFDiv %[[HALF_TYPE_ID]] %[[LOADA_ID]] %[[LOADB_ID]]
// CHECK-UNSAFE: OpStore {{.*}} %[[DIV_ID]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global half* a, global half* b)
{
  *a /= *b;
}
