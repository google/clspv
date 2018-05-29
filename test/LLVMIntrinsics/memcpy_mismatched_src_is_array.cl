// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
src_is_array(global float *A, int n, int k) {
  float src[7];
  for (int i = 0; i < 7; i++) {
    src[i] = i;
  }
  for (int i = 0; i < 7; i++) {
    A[n+i] = src[i]; // Reading whole array.
  }
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 67
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_33:%[0-9a-zA-Z_]+]] "src_is_array"
// CHECK: OpExecutionMode [[_33]] LocalSize 1 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_7]] Block
// CHECK: OpDecorate [[_30:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_30]] Binding 0
// CHECK: OpDecorate [[_31:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_31]] Binding 1
// CHECK: OpDecorate [[_32:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_32]] Binding 2
// CHECK: OpDecorate [[__arr_float_uint_7:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK: [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK: [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK: [[__struct_4]] = OpTypeStruct [[__runtimearr_float]]
// CHECK: [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[__struct_7]] = OpTypeStruct [[_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK: [[_11:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_uint_7:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 7
// CHECK: [[__arr_float_uint_7]] = OpTypeArray [[_float]] [[_uint_7]]
// CHECK: [[__ptr_Function__arr_float_uint_7:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[__arr_float_uint_7]]
// CHECK: [[__ptr_Function_float:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[_float]]
// CHECK: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK: [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK: [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK: [[_uint_6:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 6
// CHECK: [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK: [[_float_1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1
// CHECK: [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK: [[_float_3:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 3
// CHECK: [[_float_4:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 4
// CHECK: [[_float_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 5
// CHECK: [[_float_6:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 6
// CHECK: [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_31]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK: [[_32]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK: [[_33]] = OpFunction [[_void]] None [[_11]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Function__arr_float_uint_7]] Function
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_31]] [[_uint_0]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_36]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_0]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_1]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_2]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_3]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_4]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_5]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_6]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_38]]
// CHECK: OpStore [[_45]] [[_float_0]]
// CHECK: OpStore [[_39]] [[_float_1]]
// CHECK: OpStore [[_40]] [[_float_2]]
// CHECK: OpStore [[_41]] [[_float_3]]
// CHECK: OpStore [[_42]] [[_float_4]]
// CHECK: OpStore [[_43]] [[_float_5]]
// CHECK: OpStore [[_44]] [[_float_6]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_0]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_0]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_47]]
// CHECK: OpCopyMemory [[_48]] [[_46]] Aligned 4
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_1]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_1]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_50]]
// CHECK: OpCopyMemory [[_51]] [[_49]] Aligned 4
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_2]]
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_2]]
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_53]]
// CHECK: OpCopyMemory [[_54]] [[_52]] Aligned 4
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_3]]
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_3]]
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_56]]
// CHECK: OpCopyMemory [[_57]] [[_55]] Aligned 4
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_4]]
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_4]]
// CHECK: [[_60:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_59]]
// CHECK: OpCopyMemory [[_60]] [[_58]] Aligned 4
// CHECK: [[_61:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_5]]
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_5]]
// CHECK: [[_63:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_62]]
// CHECK: OpCopyMemory [[_63]] [[_61]] Aligned 4
// CHECK: [[_64:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_35]] [[_uint_6]]
// CHECK: [[_65:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_6]]
// CHECK: [[_66:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_65]]
// CHECK: OpCopyMemory [[_66]] [[_64]] Aligned 4
// CHECK: OpReturn
// CHECK: OpFunctionEnd
