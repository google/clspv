// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpDecorate %[[BUILTIN_X_ID:[a-zA-Z0-9_]*]] SpecId 0
// CHECK: OpDecorate %[[BUILTIN_Y_ID:[a-zA-Z0-9_]*]] SpecId 1
// CHECK: OpDecorate %[[BUILTIN_Z_ID:[a-zA-Z0-9_]*]] SpecId 2
// CHECK: OpDecorate %[[BUILTIN_ID:[a-zA-Z0-9_]*]] BuiltIn WorkgroupSize
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[BUILTIN_X_ID]] = OpSpecConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[BUILTIN_Y_ID]] = OpSpecConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[BUILTIN_Z_ID]] = OpSpecConstant %[[UINT_TYPE_ID]] 1
// CHECK: %[[BUILTIN_ID]] = OpSpecConstantComposite %[[UINT3_TYPE_ID]] %[[BUILTIN_X_ID]] %[[BUILTIN_Y_ID]] %[[BUILTIN_Z_ID]]

// CHECK: [[hack0:%[a-zA-Z0-9_]+]] = OpBitwiseAnd %[[UINT3_TYPE_ID]] %[[BUILTIN_ID]] %[[BUILTIN_ID]]
// CHECK: [[comp0:%[a-zA-Z0-9_]+]] = OpCompositeExtract %[[UINT_TYPE_ID]] [[hack0]] 0
// CHECK: OpStore {{.*}} [[comp0]]

// CHECK: [[hack1:%[a-zA-Z0-9_]+]] = OpBitwiseAnd %[[UINT3_TYPE_ID]] %[[BUILTIN_ID]] %[[BUILTIN_ID]]
// CHECK: [[comp1:%[a-zA-Z0-9_]+]] = OpCompositeExtract %[[UINT_TYPE_ID]] [[hack1]]
// CHECK: OpStore {{.*}} [[comp1]]

// CHECK: [[hack2:%[a-zA-Z0-9_]+]] = OpBitwiseAnd %[[UINT3_TYPE_ID]] %[[BUILTIN_ID]] %[[BUILTIN_ID]]
// CHECK: [[comp2:%[a-zA-Z0-9_]+]] = OpCompositeExtract %[[UINT_TYPE_ID]] [[hack2]]
// CHECK: OpStore {{.*}} [[comp2]]

// CHECK: OpStore {{.*}} %[[CONSTANT_1_ID]]

void kernel foo(global uint* a)
{
  a[0] = get_local_size(0);
  a[1] = get_local_size(1);
  a[2] = get_local_size(2);
  a[3] = get_local_size(3);
}
