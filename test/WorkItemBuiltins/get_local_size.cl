// RUN: clspv -uniform-workgroup-size %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpDecorate %[[BUILTIN_ID:[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[UINT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK-DAG: %[[CONSTANT_3_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 3
// CHECK-DAG: %[[BUILTIN_ID]] = OpConstantComposite %[[UINT3_TYPE_ID]] %[[CONSTANT_1_ID]] %[[CONSTANT_1_ID]] %[[CONSTANT_1_ID]]
// CHECK: %[[BUILTIN_VAR_ID:[a-zA-Z0-9_]*]] = OpVariable {{.*}} Private %[[BUILTIN_ID]]
// CHECK: %[[LOAD1_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[UINT_TYPE_ID]]
// CHECK: %[[RESULT_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[UINT_TYPE_ID]] %[[GET_LOCAL_SIZE_ID:[a-zA-Z0-9_]*]] %[[LOAD1_ID]]
// CHECK: OpStore {{.*}} %[[CONSTANT_1_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  a[get_local_size(b)] = get_local_size(3);
}

// CHECK: %[[GET_LOCAL_SIZE_ID]] = OpFunction %[[UINT_TYPE_ID]]
// CHECK: %[[FUNC_PARAM_ID:[a-zA-Z0-9_]*]] = OpFunctionParameter %[[UINT_TYPE_ID]]
// CHECK: %[[COND_ID:[a-zA-Z0-9_]*]] = OpULessThan %[[BOOL_TYPE_ID]] %[[FUNC_PARAM_ID]] %[[CONSTANT_3_ID]]
// CHECK: %[[SELECT1_ID:[a-zA-Z0-9_]*]] = OpSelect %[[UINT_TYPE_ID]] %[[COND_ID]] %[[FUNC_PARAM_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[hack:[a-zA-Z0-9_]+]] = OpBitwiseAnd %[[UINT3_TYPE_ID]] %[[BUILTIN_ID]] %[[BUILTIN_ID]]
// CHECK: [[result:%[a-zA-Z0-9_]*]] = OpVectorExtractDynamic %[[UINT_TYPE_ID]] %[[hack]] %[[SELECT1_ID]]
// CHECK: %[[SELECT2_ID:[a-zA-Z0-9_]*]] = OpSelect %[[UINT_TYPE_ID]] %[[COND_ID]] [[result]] %[[CONSTANT_1_ID]]
// CHECK: OpReturnValue %[[SELECT2_ID]]
