// RUN: clspv %s -o %t.spv -inline-entry-points -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_UNDEF:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[VEC_BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 4
// CHECK-DAG: %[[CONSTANT_FLOAT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 1
// CHECK-DAG: %[[COMPOSITE_FLOAT_1_ID:[a-zA-Z0-9_]*]] = OpConstantComposite %[[FLOAT_VECTOR_TYPE_ID]] %[[CONSTANT_FLOAT_1_ID]] %[[CONSTANT_FLOAT_1_ID]] %[[CONSTANT_FLOAT_1_ID]] %[[FLOAT_UNDEF]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[ABS_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_VECTOR_TYPE_ID]] {{.*}} FAbs %[[LOADB_ID]]
// CHECK: %[[CMP0_ID:[a-zA-Z0-9_]*]] = OpFOrdGreaterThan %[[VEC_BOOL_TYPE_ID]] %[[ABS_ID]]
// CHECK: %[[CMP1_ID:[a-zA-Z0-9_]*]] = OpFOrdLessThan %[[VEC_BOOL_TYPE_ID]] %[[ABS_ID]]
// CHECK: %[[SELECT0_ID:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT_VECTOR_TYPE_ID]] %[[CMP0_ID]]
// CHECK: %[[SELECT1_ID:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT_VECTOR_TYPE_ID]] %[[CMP1_ID]] {{.*}} %[[SELECT0_ID]]
// CHECK: %[[MUL_ID:[a-zA-Z0-9_]*]] = OpFMul %[[FLOAT_VECTOR_TYPE_ID]] %[[LOADB_ID]] %[[SELECT1_ID]]
// CHECK: %[[DIV_ID:[a-zA-Z0-9_]*]] = OpFDiv %[[FLOAT_VECTOR_TYPE_ID]] %[[COMPOSITE_FLOAT_1_ID]] %[[MUL_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpFMul %[[FLOAT_VECTOR_TYPE_ID]] %[[DIV_ID]] %[[SELECT1_ID]]
// CHECK: %[[OP_ID4:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[FLOAT_VECTOR_TYPE_ID]] %[[FLOAT_UNDEF]] %[[OP_ID]] 3
// CHECK: OpStore {{.*}} %[[OP_ID4]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = half_recip(*b);
}
