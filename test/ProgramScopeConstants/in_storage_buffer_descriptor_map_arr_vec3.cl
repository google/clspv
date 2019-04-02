// RUN: clspv %s -o %t.spv -descriptormap=%t.map -module-constants-in-storage-buffer
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Proves ConstantDataVector and ConstantArray work.

__constant uint3 ppp[2] = {(uint3)(1,2,3), (uint3)(5)};

kernel void foo(global uint* A, uint i) { *A = ppp[i].x; }



// MAP: constant,descriptorSet,1,binding,0,kind,buffer,hexbytes,0100000002000000030000000000000005000000050000000500000000000000
// MAP-NEXT: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,i,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod,argSize,4

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 34
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_26:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_18:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpMemberDecorate [[__struct_13:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 1
// CHECK:  OpDecorate [[_23]] Binding 0
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_24]] Binding 0
// CHECK:  OpDecorate [[_25:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_25]] Binding 1
// CHECK:  OpDecorate [[__arr_v3uint_uint_2:%[0-9a-zA-Z_]+]] ArrayStride 16
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
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[__arr_v3uint_uint_2]] = OpTypeArray [[_v3uint]] [[_uint_2]]
// CHECK:  [[__struct_13]] = OpTypeStruct [[__arr_v3uint_uint_2]]
// CHECK:  [[__ptr_StorageBuffer__struct_13:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CHECK:  [[__ptr_StorageBuffer_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v3uint]]
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_18]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_19]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_20]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_18]] [[_19]] [[_20]]
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK:  [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_26]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_24]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_25]] [[_uint_0]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v3uint]] [[_23]] [[_uint_0]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_v3uint]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_32]] 0
// CHECK:  OpStore [[_28]] [[_33]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
