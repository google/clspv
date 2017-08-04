// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -S -o %t3.spvasm -cluster-pod-kernel-args
// RUN: FileCheck %s < %t3.spvasm -check-prefix=CLUSTER
// RUN: clspv %s -o %t4.spv -cluster-pod-kernel-args
// RUN: spirv-dis -o %t4.spvasm %t4.spv
// RUN: FileCheck %s < %t4.spvasm -check-prefix=CLUSTER
// RUN: spirv-val --target-env vulkan1.0 %t4.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 34
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1

// CHECK: OpMemberDecorate %[[ARG2_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG2_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[ARG3_DYNAMIC_ARRAY_TYPE_ID:[a-zA-Z0-9_]*]] ArrayStride 16

// CHECK: OpMemberDecorate %[[ARG3_STRUCT_TYPE_ID:[a-zA-Z0-9_]*]] 0 Offset 0
// CHECK: OpDecorate %[[ARG3_STRUCT_TYPE_ID]] Block

// CHECK: OpDecorate %[[ARG0_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG0_ID]] Binding 0

// CHECK: OpDecorate %[[ARG1_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG1_ID]] Binding 1
// CHECK: OpDecorate %[[ARG1_ID]] NonWritable

// CHECK: OpDecorate %[[ARG2_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG2_ID]] Binding 2

// CHECK: OpDecorate %[[ARG3_ID:[a-zA-Z0-9_]*]] DescriptorSet 0
// CHECK: OpDecorate %[[ARG3_ID]] Binding 3

// CHECK: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[SAMPLER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampler
// CHECK: %[[ARG0_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer UniformConstant %[[SAMPLER_TYPE_ID]]

// CHECK: %[[READ_ONLY_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeImage %[[FLOAT_TYPE_ID]] 2D 0 0 0 1 Unknown
// CHECK: %[[ARG1_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer UniformConstant %[[READ_ONLY_IMAGE_TYPE_ID]]

// CHECK: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK: %[[ARG2_STRUCT_TYPE_ID]] = OpTypeStruct %[[FLOAT2_TYPE_ID]]
// CHECK: %[[ARG2_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG2_STRUCT_TYPE_ID]]

// CHECK: %[[FLOAT2_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT2_TYPE_ID]]

// CHECK: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: %[[FLOAT4_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[FLOAT4_TYPE_ID]]

// CHECK: %[[ARG3_DYNAMIC_ARRAY_TYPE_ID]] = OpTypeRuntimeArray %[[FLOAT4_TYPE_ID]]
// CHECK: %[[ARG3_STRUCT_TYPE_ID]] = OpTypeStruct %[[ARG3_DYNAMIC_ARRAY_TYPE_ID]]
// CHECK: %[[ARG3_POINTER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypePointer StorageBuffer %[[ARG3_STRUCT_TYPE_ID]]

// CHECK: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK: %[[FOO_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]
// CHECK: %[[SAMPLED_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampledImage %[[READ_ONLY_IMAGE_TYPE_ID]]

// CHECK: %[[FP_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0
// CHECK: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0

// CHECK: %[[ARG0_ID]] = OpVariable %[[ARG0_POINTER_TYPE_ID]] UniformConstant
// CHECK: %[[ARG1_ID]] = OpVariable %[[ARG1_POINTER_TYPE_ID]] UniformConstant
// CHECK: %[[ARG2_ID]] = OpVariable %[[ARG2_POINTER_TYPE_ID]] StorageBuffer
// CHECK: %[[ARG3_ID]] = OpVariable %[[ARG3_POINTER_TYPE_ID]] StorageBuffer

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[FOO_TYPE_ID]]
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[S_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[SAMPLER_TYPE_ID]] %[[ARG0_ID]]
// CHECK: %[[I_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[READ_ONLY_IMAGE_TYPE_ID]] %[[ARG1_ID]]
// CHECK: %[[C_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT2_POINTER_TYPE_ID]] %[[ARG2_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[C_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT2_TYPE_ID]] %[[C_ACCESS_CHAIN_ID]]
// CHECK: %[[A_ACCESS_CHAIN_ID:[a-zA-Z0-9_]*]] = OpAccessChain %[[FLOAT4_POINTER_TYPE_ID]] %[[ARG3_ID]] %[[CONSTANT_0_ID]] %[[CONSTANT_0_ID]]
// CHECK: %[[SAMPLED_IMAGE_ID:[a-zA-Z0-9_]*]] = OpSampledImage %[[SAMPLED_IMAGE_TYPE_ID]] %[[I_LOAD_ID]] %[[S_LOAD_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpImageSampleExplicitLod %[[FLOAT4_TYPE_ID]] %[[SAMPLED_IMAGE_ID]] %[[C_LOAD_ID]] Lod %[[FP_CONSTANT_0_ID]]
// CHECK: OpStore %[[A_ACCESS_CHAIN_ID]] %[[OP_ID]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image2d_t i, float2 c, global float4* a)
{
  *a = read_imagef(i, s, c);
}

// In a second round, check -cluster-pod-kernel-args
// CLUSTER: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]] "foo"
// CLUSTER: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CLUSTER: [[sampler:%[a-zA-Z0-9_]+]] = OpTypeSampler
// CLUSTER: [[image:%[a-zA-Z0-9_]+]] = OpTypeImage [[float]] 2D 0 0 0 1 Unknown
// CLUSTER: [[vec2:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 2
// CLUSTER: [[st_vec2:%[a-zA-Z0-9_]+]] = OpTypeStruct [[vec2]]
// CLUSTER: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CLUSTER: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CLUSTER: [[void_fn:%[a-zA-Z0-9_]+]] = OpTypeFunction [[void]]
// CLUSTER: [[zero:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0

// CLUSTER: [[fooinner:%[a-zA-A0-9]+]] = OpFunction [[void]] None
// CLUSTER: OpFunctionEnd

// Match the wrapper kernel function.
// CLUSTER: [[foo]] = OpFunction [[void]] None [[void_fn]]
// CLUSTER-NEXT: OpLabel
// CLUSTER-NEXT: [[sampler_val:%[a-zA-Z0-9_]+]] = OpLoad [[sampler]]
// CLUSTER-NEXT: [[image_val:%[a-zA-Z0-9_]+]] = OpLoad [[image]]
// CLUSTER-NEXT: [[a_base:%[a-zA-Z0-9_]+]] = OpAccessChain %{{[a-zA-Z0-9_]+}} %{{[a-zA-Z0-9_]+}} [[zero]] [[zero]]
// CLUSTER-NEXT: [[podargs_base:%[a-zA-Z0-9_]+]] = OpAccessChain %{{[a-zA-Z0-9_]+}} %{{[a-zA-Z0-9_]+}} [[zero]]
// CLUSTER-NEXT: [[podargs:%[a-zA-Z0-9_]+]] = OpLoad [[st_vec2]] [[podargs_base]]
// CLUSTER-NEXT: [[vec2_val:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[vec2]] [[podargs]] 0
// CLUSTER-NEXT: = OpFunctionCall [[void]] [[fooinner]] [[sampler_val]] [[image_val]] [[vec2_val]] [[a_base]]
