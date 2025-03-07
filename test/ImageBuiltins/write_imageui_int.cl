// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[WRITE_ONLY_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeImage %[[UINT_TYPE_ID]] 1D 0 0 0 2 Unknown
// CHECK-DAG: %[[UINT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 4
// CHECK: %[[I_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[WRITE_ONLY_IMAGE_TYPE_ID]]
// CHECK: OpImageWrite %[[I_LOAD_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(write_only image1d_t i, int c, uint4 a)
{
  write_imageui(i, c, a);
}

