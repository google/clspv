// RUN: clspv %s -S -o %t.spvasm -descriptormap=%t.map -module-constants-in-storage-buffer
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: clspv %s -o %t.spv -descriptormap=%t.map -module-constants-in-storage-buffer
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Proves ConstantDataVector and ConstantArray work.

__constant uint ppp[2][3] = {{1,2,3}, {5}};

kernel void foo(global uint* A, uint i) { *A = ppp[i][i]; }

// MAP: constant,descriptorSet,0,binding,0,kind,buffer,hexbytes,010000000200000003000000050000000000000000000000
// MAP-NEXT: kernel,foo,arg,A,argOrdinal,0,descriptorSet,1,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,i,argOrdinal,1,descriptorSet,1,binding,1,offset,0,argKind,pod

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 42
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_34:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_26:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpMemberDecorate [[__struct_14:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_31:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_31]] Binding 0
// CHECK: OpDecorate [[_32:%[0-9a-zA-Z_]+]] DescriptorSet 1
// CHECK: OpDecorate [[_32]] Binding 0
// CHECK: OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 1
// CHECK: OpDecorate [[_33]] Binding 1
// CHECK: OpDecorate [[__arr_uint_uint_3:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpDecorate [[__arr__arr_uint_uint_3_uint_2:%[0-9a-zA-Z_]+]] ArrayStride 12
// CHECK: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK: [[__struct_4]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK: [[__struct_6]] = OpTypeStruct [[_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK: [[_9:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK: [[__arr_uint_uint_3]] = OpTypeArray [[_uint]] [[_uint_3]]
// CHECK: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[__arr__arr_uint_uint_3_uint_2]] = OpTypeArray [[__arr_uint_uint_3]] [[_uint_2]]
// CHECK: [[__struct_14]] = OpTypeStruct [[__arr__arr_uint_uint_3_uint_2]]
// CHECK: [[__ptr_StorageBuffer__struct_14:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_14]]
// CHECK: [[__ptr_StorageBuffer__arr__arr_uint_uint_3_uint_2:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__arr__arr_uint_uint_3_uint_2]]
// CHECK: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_21:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__arr_uint_uint_3]] [[_uint_1]] [[_uint_2]] [[_uint_3]]
// CHECK: [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK: [[_23:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__arr_uint_uint_3]] [[_uint_5]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__arr__arr_uint_uint_3_uint_2]] [[_21]] [[_23]]
// CHECK: [[_25:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__struct_14]] [[_24]]
// CHECK: [[_26]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_27]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_28]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_26]] [[_27]] [[_28]]
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_31]] = OpVariable [[__ptr_StorageBuffer__struct_14]] StorageBuffer
// CHECK: [[_32]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_33]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_34]] = OpFunction [[_void]] None [[_9]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_32]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_37]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__arr__arr_uint_uint_3_uint_2]] [[_31]] [[_uint_0]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_39]] [[_38]] [[_38]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_40]]
// CHECK: OpStore [[_36]] [[_41]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
