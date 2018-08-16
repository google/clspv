// RUN: clspv %s -S -o %t.spvasm -cluster-pod-kernel-args -descriptormap=%t.map
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck %s < %t.map -check-prefix=MAP
// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args -descriptormap=%t2.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck %s < %t2.map -check-prefix=MAP
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct S {
  int a; int b;
} S;

kernel void foo(local float *L, global float* A, S local* LS, constant float* C, float f, float g ) {
 *A = *L + *C + f + g + LS->a;
}

//      MAP: kernel,foo,arg,L,argOrdinal,0,argKind,local,arrayElemSize,4,arrayNumElemSpecId,3
// MAP-NEXT: kernel,foo,arg,A,argOrdinal,1,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,LS,argOrdinal,2,argKind,local,arrayElemSize,8,arrayNumElemSpecId,4
// MAP-NEXT: kernel,foo,arg,C,argOrdinal,3,descriptorSet,0,binding,1,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,f,argOrdinal,4,descriptorSet,0,binding,2,offset,0,argKind,pod
// MAP-NEXT: kernel,foo,arg,g,argOrdinal,5,descriptorSet,0,binding,2,offset,4,argKind,pod
// MAP-NOT: kernel

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 54
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_38:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_30:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_31:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_32:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_13:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_13]] Block
// CHECK:  OpMemberDecorate [[__struct_15:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpMemberDecorate [[__struct_15]] 1 Offset 4
// CHECK:  OpMemberDecorate [[__struct_16:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_16]] Block
// CHECK:  OpMemberDecorate [[__struct_24:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpMemberDecorate [[__struct_24]] 1 Offset 4
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_35:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_35]] Binding 0
// CHECK:  OpDecorate [[_36:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_36]] Binding 1
// CHECK:  OpDecorate [[_36]] NonWritable
// CHECK:  OpDecorate [[_37:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_37]] Binding 2
// CHECK:  OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK:  OpDecorate [[_7:%[0-9a-zA-Z_]+]] SpecId 4
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_13]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_13:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CHECK:  [[__struct_15]] = OpTypeStruct [[_float]] [[_float]]
// CHECK:  [[__struct_16]] = OpTypeStruct [[__struct_15]]
// CHECK:  [[__ptr_StorageBuffer__struct_16:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_16]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_20:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_Workgroup_float:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_float]]
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_15:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_15]]
// CHECK:  [[__ptr_Workgroup_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_uint]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[__struct_24]] = OpTypeStruct [[_uint]] [[_uint]]
// CHECK:  [[__ptr_Workgroup__struct_24:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__struct_24]]
// CHECK:  [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_2]]
// CHECK:  [[__ptr_Workgroup__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_float_2]]
// CHECK:  [[_7]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[__arr__struct_24_7:%[0-9a-zA-Z_]+]] = OpTypeArray [[__struct_24]] [[_7]]
// CHECK:  [[__ptr_Workgroup__arr__struct_24_7:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr__struct_24_7]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_30]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_31]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_32]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_30]] [[_31]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_35]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK:  [[_36]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK:  [[_37]] = OpVariable [[__ptr_StorageBuffer__struct_16]] StorageBuffer
// CHECK:  [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_float_2]] Workgroup
// CHECK:  [[_6:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr__struct_24_7]] Workgroup
// CHECK:  [[_38]] = OpFunction [[_void]] None [[_20]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_5:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_float]] [[_1]] [[_uint_0]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_35]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_36]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_15]] [[_37]] [[_uint_0]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpLoad [[__struct_15]] [[_42]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_43]] 0
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_43]] 1
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_5]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_41]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_46]] [[_47]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_44]] [[_48]]
// CHECK:  [[_50:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_45]] [[_49]]
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_6]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_51]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpConvertSToF [[_float]] [[_52]]
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_50]] [[_53]]
// CHECK:  OpStore [[_40]] [[_54]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
