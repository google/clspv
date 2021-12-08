// RUN: clspv %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 4
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[BOOL3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 3
// CHECK-DAG: %[[BOOL4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 4
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK-DAG: %[[UINT4_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstantNull %[[UINT4_TYPE_ID]]
// CHECK-DAG: %[[UNDEFVEC4:[a-zA-Z0-9_]+]] = OpUndef %[[BOOL4_TYPE_ID]]
// CHECK: %[[B_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT4_TYPE_ID]]
// CHECK: %[[CMP_ID:[a-zA-Z0-9_]*]] = OpSLessThan %[[BOOL4_TYPE_ID]] %[[B_LOAD_ID]] %[[UINT4_CONSTANT_0_ID]]
// CHECK: %[[CMP3:[a-zA-Z0-9_]+]] = OpVectorShuffle %[[BOOL3_TYPE_ID]] %[[CMP_ID]] %[[UNDEFVEC4]] 0 1 2
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpAll %[[BOOL_TYPE_ID]] %[[CMP3]]
// CHECK: %[[CAS_ID:[a-zA-Z0-9_]*]] = OpSelect %[[UINT_TYPE_ID]] %[[OP_ID]] %[[CONSTANT_1_ID]] %[[CONSTANT_0_ID]]
// CHECK: OpStore {{.*}} %[[CAS_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global int3* b)
{
  *a = all(b[0]);
}
