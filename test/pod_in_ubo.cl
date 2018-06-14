kernel void foo(int k, global int *A, int b) { *A = k + b; }

// RUN: clspv %s -S -o %t.spvasm -descriptormap=%t.map -pod-ubo
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: clspv %s -o %t.spv -descriptormap=%t.map -pod-ubo
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// MAP: kernel,foo,arg,k,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,pod_ubo
// MAP-NEXT: kernel,foo,arg,A,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,b,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,pod_ubo


// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 30
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_22:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_14:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_15:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_16:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpMemberDecorate [[__struct_2:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_2]] Block
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_19]] Binding 0
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_20]] Binding 1
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_21]] Binding 2
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__struct_2]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_Uniform__struct_2:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[__struct_2]]
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_5]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_8:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_Uniform_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[_uint]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_14]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_15]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_16]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_14]] [[_15]] [[_16]]
// CHECK:  [[_18:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_19]] = OpVariable [[__ptr_Uniform__struct_2]] Uniform
// CHECK:  [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_21]] = OpVariable [[__ptr_Uniform__struct_2]] Uniform
// CHECK:  [[_22]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Uniform_uint]] [[_19]] [[_uint_0]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_24]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_20]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Uniform_uint]] [[_21]] [[_uint_0]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_27]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_28]] [[_25]]
// CHECK:  OpStore [[_26]] [[_29]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
