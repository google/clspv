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
// CHECK-DAG: OpCapability Shader
// CHECK-DAG: OpCapability VariablePointers
// CHECK-NOT: OpCapability StorageImageReadWithoutFormat
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

// CLUSTER: ; SPIR-V
// CLUSTER: ; Version: 1.0
// CLUSTER: ; Generator: Codeplay; 0
// CLUSTER: ; Bound: 36
// CLUSTER: ; Schema: 0
// CLUSTER: OpCapability Shader
// CLUSTER: OpCapability VariablePointers
// CLUSTER: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CLUSTER: OpExtension "SPV_KHR_variable_pointers"
// CLUSTER: OpMemoryModel Logical GLSL450
// CLUSTER: OpEntryPoint GLCompute [[_26:%[a-zA-Z0-9_]+]] "foo"
// CLUSTER: OpExecutionMode [[_26]] LocalSize 1 1 1
// CLUSTER: OpSource OpenCL_C 120
// CLUSTER: OpDecorate [[__runtimearr_v4float:%[a-zA-Z0-9_]+]] ArrayStride 16
// CLUSTER: OpMemberDecorate [[__struct_9:%[a-zA-Z0-9_]+]] 0 Offset 0
// CLUSTER: OpDecorate [[__struct_9]] Block
// CLUSTER: OpMemberDecorate [[__struct_12:%[a-zA-Z0-9_]+]] 0 Offset 0
// CLUSTER: OpMemberDecorate [[__struct_13:%[a-zA-Z0-9_]+]] 0 Offset 0
// CLUSTER: OpDecorate [[__struct_13]] Block
// CLUSTER: OpDecorate [[_22:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_22]] Binding 0
// CLUSTER: OpDecorate [[_23:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_23]] Binding 1
// CLUSTER: OpDecorate [[_23]] NonWritable
// CLUSTER: OpDecorate [[_24:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_24]] Binding 2
// CLUSTER: OpDecorate [[_25:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_25]] Binding 3
// CLUSTER: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CLUSTER: [[_2:%[a-zA-Z0-9_]+]] = OpTypeSampler
// CLUSTER: [[__ptr_UniformConstant_2:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[_2]]
// CLUSTER: [[_4:%[a-zA-Z0-9_]+]] = OpTypeImage [[_float]] 2D 0 0 0 1 Unknown
// CLUSTER: [[__ptr_UniformConstant_4:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[_4]]
// CLUSTER: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CLUSTER: [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CLUSTER: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CLUSTER: [[__struct_9]] = OpTypeStruct [[__runtimearr_v4float]]
// CLUSTER: [[__ptr_StorageBuffer__struct_9:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CLUSTER: [[_v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 2
// CLUSTER: [[__struct_12]] = OpTypeStruct [[_v2float]]
// CLUSTER: [[__struct_13]] = OpTypeStruct [[__struct_12]]
// CLUSTER: [[__ptr_StorageBuffer__struct_13:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CLUSTER: [[__ptr_StorageBuffer__struct_12:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CLUSTER: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CLUSTER: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CLUSTER: [[_18:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CLUSTER: [[_19:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[_4]]
// CLUSTER: [[_float_0:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0
// CLUSTER: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CLUSTER: [[_22]] = OpVariable [[__ptr_UniformConstant_2]] UniformConstant
// CLUSTER: [[_23]] = OpVariable [[__ptr_UniformConstant_4]] UniformConstant
// CLUSTER: [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CLUSTER: [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CLUSTER: [[_26]] = OpFunction [[_void]] None [[_18]]
// CLUSTER: [[_27:%[a-zA-Z0-9_]+]] = OpLabel
// CLUSTER: [[_28:%[a-zA-Z0-9_]+]] = OpLoad [[_2]] [[_22]]
// CLUSTER: [[_29:%[a-zA-Z0-9_]+]] = OpLoad [[_4]] [[_23]]
// CLUSTER: [[_30:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_24]] [[_uint_0]] [[_uint_0]]
// CLUSTER: [[_31:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_12]] [[_25]] [[_uint_0]]
// CLUSTER: [[_32:%[a-zA-Z0-9_]+]] = OpLoad [[__struct_12]] [[_31]]
// CLUSTER: [[_33:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_v2float]] [[_32]] 0
// CLUSTER: [[_34:%[a-zA-Z0-9_]+]] = OpSampledImage [[_19]] [[_29]] [[_28]]
// CLUSTER: [[_35:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod [[_v4float]] [[_34]] [[_33]] Lod [[_float_0]]
// CLUSTER: OpStore [[_30]] [[_35]]
// CLUSTER: OpReturn
// CLUSTER: OpFunctionEnd
