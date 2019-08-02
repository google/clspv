// RUN: clspv %s -o %t.spv -f16bit_storage
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[SHORT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 16 0
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT2_TYPE_ID]]
// CHECK: %[[LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
// CHECK: %[[INSERT_ID:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[FLOAT2_TYPE_ID]] %[[LOAD_ID]] %[[UNDEF_ID]] 0
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_TYPE_ID]] {{.*}} PackHalf2x16 %[[INSERT_ID]]
// CHECK: %[[CONVERT_ID:[a-zA-Z0-9_]*]] = OpUConvert %[[SHORT_TYPE_ID]] %[[OP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short* a, global float* b)
{
  vstore_half(*b, 0, (global half *)a);
}
