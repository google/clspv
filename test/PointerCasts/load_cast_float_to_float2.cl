// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
















void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float2* b, int i)
{
  *b = ((global float2*)a)[i];
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 34
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_23:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_23]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpDecorate [[__runtimearr_v2float:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_10]] Block
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_20]] Binding 0
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_21]] Binding 1
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 2
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK:  [[__runtimearr_v2float]] = OpTypeRuntimeArray [[_v2float]]
// CHECK:  [[__struct_7]] = OpTypeStruct [[__runtimearr_v2float]]
// CHECK:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__struct_10]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK:  [[_23]] = OpFunction [[_void]] None [[_13]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_21]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_22]] [[_uint_0]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_26]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_27]] [[_uint_1]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_20]] [[_uint_0]] [[_28]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_28]] [[_uint_1]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_20]] [[_uint_0]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_32]]
// CHECK:  [[construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2float]] [[_30]] [[_33]]
// CHECK:  OpStore [[_25]] [[construct]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
