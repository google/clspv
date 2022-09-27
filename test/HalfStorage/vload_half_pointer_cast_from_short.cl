// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[SHORT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 16 0
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[SHORT_TYPE_ID]]
// CHECK: %[[CONVERT_ID:[a-zA-Z0-9_]*]] = OpUConvert %[[UINT_TYPE_ID]] %[[LOAD_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT2_TYPE_ID]] {{.*}} UnpackHalf2x16 %[[CONVERT_ID]]
// CHECK: %[[EXTRACT_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[OP_ID]] 0

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global short* b)
{
  *a = vload_half(0, (global half *)b);
}
