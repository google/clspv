// Test https://github.com/google/clspv/issues/65
// OpSelect with vector data operands must use vector bool selector.

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* A, int c)
{
  *A = c ? (float2)(1.0,2.0) : (float2)(3.0,4.0);
}

// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[float2:[a-zA-Z0-9_]*]] = OpTypeVector %[[float]] 2
// CHECK-DAG: %[[uint:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[s_uint:[a-zA-Z0-9_]*]] = OpTypeStruct %[[uint]]
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[bool2:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 2
// CHECK-DAG: %[[uint_0:[a-zA-Z0-9_]*]] = OpConstant %[[uint]] 0
// CHECK: %[[undef:[a-zA-Z0-9_]*]] = OpUndef %[[bool2]]
// CHECK-DAG: %[[float_3:[a-zA-Z0-9_]*]] = OpConstant %[[float]] 3
// CHECK-DAG: %[[float_4:[a-zA-Z0-9_]*]] = OpConstant %[[float]] 4
// CHECK-DAG: %[[v2_3_4:[a-zA-Z0-9_]*]] = OpConstantComposite %[[float2]] %[[float_3]] %[[float_4]]
// CHECK-DAG: %[[float_1:[a-zA-Z0-9_]*]] = OpConstant %[[float]] 1
// CHECK-DAG: %[[float_2:[a-zA-Z0-9_]*]] = OpConstant %[[float]] 2
// CHECK-DAG: %[[v2_1_2:[a-zA-Z0-9_]*]] = OpConstantComposite %[[float2]] %[[float_1]] %[[float_2]]
// CHECK: %[[n:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[uint]]
// CHECK: %[[eq:[a-zA-Z0-9_]*]] = OpIEqual %[[BOOL_TYPE_ID]] %[[n]] %[[uint_0]]
// CHECK: %[[eq_vec0:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[bool2]] %[[eq]] %[[undef]] 0
// CHECK: %[[eq_splat:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[bool2]] %[[eq_vec0]] %[[undef]] 0 0
// CHECK: %[[sel:[a-zA-Z0-9_]*]] = OpSelect %[[float2]] %[[eq_splat]] %[[v2_3_4]] %[[v2_1_2]]
// CHECK: OpStore {{.*}} %[[sel]]
