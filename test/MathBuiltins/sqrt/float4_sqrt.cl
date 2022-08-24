// RUN: clspv %s -o %t.spv -cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[NAN:[a-zA-Z0-9_]*]] = OpConstant %float 0x1.8p+128
// CHECK: %[[NAN_VEC:[a-zA-Z0-9_]*]] = OpConstantComposite %[[FLOAT_VECTOR_TYPE_ID]] %[[NAN]]
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[ZERO_COMP:[a-zA-Z0-9_]*]] = OpFOrdGreaterThanEqual %{{[a-zA-Z0-9_]*}} %[[LOADB_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_VECTOR_TYPE_ID]] %[[EXT_INST]] Sqrt %[[LOADB_ID]]
// CHECK: %[[SELECT_ID:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT_VECTOR_TYPE_ID]] %[[ZERO_COMP]] %[[OP_ID]] %[[NAN_VEC]]
// CHECK: OpStore {{.*}} %[[SELECT_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b)
{
  *a = sqrt(*b);
}
