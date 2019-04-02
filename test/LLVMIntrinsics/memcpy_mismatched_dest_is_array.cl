// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
dest_is_array(global float *A, int n, int k) {
  float dest[7];
  for (int i = 0; i < 7; i++) {
    // Writing the whole array.
    dest[i] = A[i];
  }
  A[n] = dest[k];
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 50
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_26:%[0-9a-zA-Z_]+]] "dest_is_array"
// CHECK:  OpExecutionMode [[_26]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_6]] Block
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 0
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_24]] Binding 1
// CHECK:  OpDecorate [[_25:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_25]] Binding 2
// CHECK:  OpDecorate [[__arr_float_uint_7:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__struct_6]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_9:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_uint_7:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 7
// CHECK:  [[__arr_float_uint_7]] = OpTypeArray [[_float]] [[_uint_7]]
// CHECK:  [[__ptr_Function__arr_float_uint_7:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[__arr_float_uint_7]]
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[__ptr_Function_float:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[_float]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK:  [[_uint_6:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 6
// CHECK:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_26]] = OpFunction [[_void]] None [[_9]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Function__arr_float_uint_7]] Function
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_24]] [[_uint_0]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_25]] [[_uint_0]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_0]]
// CHECK:  OpCopyMemory [[_34]] [[_33]] Aligned 4
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_1]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_1]]
// CHECK:  OpCopyMemory [[_36]] [[_35]] Aligned 4
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_2]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_2]]
// CHECK:  OpCopyMemory [[_38]] [[_37]] Aligned 4
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_3]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_3]]
// CHECK:  OpCopyMemory [[_40]] [[_39]] Aligned 4
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_4]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_4]]
// CHECK:  OpCopyMemory [[_42]] [[_41]] Aligned 4
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_5]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_5]]
// CHECK:  OpCopyMemory [[_44]] [[_43]] Aligned 4
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_6]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_uint_6]]
// CHECK:  OpCopyMemory [[_46]] [[_45]] Aligned 4
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_float]] [[_28]] [[_32]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_47]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_30]]
// CHECK:  OpStore [[_49]] [[_48]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
