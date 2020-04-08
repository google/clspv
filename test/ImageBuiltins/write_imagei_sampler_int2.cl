// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[INT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 1
// CHECK-DAG: %[[WRITE_ONLY_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeImage %[[INT_TYPE_ID]] 2D 0 0 0 2 Unknown
// CHECK-DAG: %[[UINT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 2
// CHECK-DAG: %[[UINT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 4
// CHECK-DAG: %[[INT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[INT_TYPE_ID]] 4
// CHECK: %[[I_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[WRITE_ONLY_IMAGE_TYPE_ID]]
// CHECK: %[[C_LOAD_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[UINT2_TYPE_ID]]
// CHECK: %[[A_LOAD_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[UINT4_TYPE_ID]]
// CHECK: %[[cast:[a-zA-Z0-9_]*]] = OpBitcast %[[INT4_TYPE_ID]] %[[A_LOAD_ID]]
// CHECK: OpImageWrite %[[I_LOAD_ID]] %[[C_LOAD_ID]] %[[cast]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(write_only image2d_t i, int2 c, int4 a)
{
  write_imagei(i, c, a);
}

