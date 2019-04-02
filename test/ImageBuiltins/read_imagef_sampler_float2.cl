// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t4.spv -cluster-pod-kernel-args
// RUN: spirv-dis -o %t4.spvasm %t4.spv
// RUN: FileCheck %s < %t4.spvasm -check-prefix=CLUSTER
// RUN: spirv-val --target-env vulkan1.0 %t4.spv


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image2d_t i, float2 c, global float4* a)
{
  *a = read_imagef(i, s, c);
}


// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 34
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_25:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_25]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_11]] Block
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_21]] Binding 0
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 1
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 2
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_24]] Binding 3
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeSampler
// CHECK-DAG:  [[__ptr_UniformConstant_2:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_2]]
// CHECK-DAG:  [[_4:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 2D 0 0 0 1 Unknown
// CHECK-DAG:  [[__ptr_UniformConstant_4:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_4]]
// CHECK-DAG:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG:  [[__struct_7]] = OpTypeStruct [[_v2float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK-DAG:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG:  [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG:  [[__struct_11]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_15:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG:  [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK-DAG:  [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG:  [[_18:%[0-9a-zA-Z_]+]] = OpTypeSampledImage [[_4]]
// CHECK-DAG:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_21]] = OpVariable [[__ptr_UniformConstant_2]] UniformConstant
// CHECK:  [[_22]] = OpVariable [[__ptr_UniformConstant_4]] UniformConstant
// CHECK:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK:  [[_25]] = OpFunction [[_void]] None [[_15]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_21]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_4]] [[_22]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_23]] [[_uint_0]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_24]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpSampledImage [[_18]] [[_28]] [[_27]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpImageSampleExplicitLod [[_v4float]] [[_32]] [[_30]] Lod [[_float_0]]
// CHECK:  OpStore [[_31]] [[_33]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd

// In a second round, check -cluster-pod-kernel-args

// CLUSTER: ; SPIR-V
// CLUSTER: ; Version: 1.0
// CLUSTER: ; Generator: Codeplay; 0
// CLUSTER: ; Bound: 36
// CLUSTER: ; Schema: 0
// CLUSTER: OpCapability Shader
// CLUSTER: OpExtension "SPV_KHR_storage_buffer_storage_class"
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
// CLUSTER: OpDecorate [[_24:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_24]] Binding 2
// CLUSTER: OpDecorate [[_25:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_25]] Binding 3
// CLUSTER-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CLUSTER-DAG: [[_2:%[a-zA-Z0-9_]+]] = OpTypeSampler
// CLUSTER-DAG: [[__ptr_UniformConstant_2:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[_2]]
// CLUSTER-DAG: [[_4:%[a-zA-Z0-9_]+]] = OpTypeImage [[_float]] 2D 0 0 0 1 Unknown
// CLUSTER-DAG: [[__ptr_UniformConstant_4:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[_4]]
// CLUSTER-DAG: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CLUSTER-DAG: [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CLUSTER-DAG: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CLUSTER-DAG: [[__struct_9]] = OpTypeStruct [[__runtimearr_v4float]]
// CLUSTER-DAG: [[__ptr_StorageBuffer__struct_9:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CLUSTER-DAG: [[_v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 2
// CLUSTER-DAG: [[__struct_12]] = OpTypeStruct [[_v2float]]
// CLUSTER-DAG: [[__struct_13]] = OpTypeStruct [[__struct_12]]
// CLUSTER-DAG: [[__ptr_StorageBuffer__struct_13:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CLUSTER-DAG: [[__ptr_StorageBuffer__struct_12:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CLUSTER-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CLUSTER-DAG: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CLUSTER-DAG: [[_18:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CLUSTER-DAG: [[_19:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[_4]]
// CLUSTER-DAG: [[_float_0:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0
// CLUSTER-DAG: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
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
