// RUN: clspv %s -o %t.spv -descriptormap=%t.map -module-constants-in-storage-buffer
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uint* A, uint i) { A[i] = 0; }

// MAP-NOT: constant,descriptorSet
// MAP: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NOT: constant,descriptorSet
// MAP-NEXT: kernel,foo,arg,i,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod,argSize,4
// MAP-NOT: constant,descriptorSet

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 25
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_20:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_13:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_14:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_15:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_18:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_18]] Binding 0
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_19]] Binding 1
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[__struct_5]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_8:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_13]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_14]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_15]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_13]] [[_14]] [[_15]]
// CHECK:  [[_17:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_18]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_20]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_22]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_18]] [[_uint_0]] [[_23]]
// CHECK:  OpStore [[_24]] [[_uint_0]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
