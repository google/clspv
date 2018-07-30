// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv




struct Thing
{
  float a[128];
};






float bar(global struct Thing* a)
{
  return a[0].a[5];
}


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global struct Thing* b)
{
  *a = bar(b);
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 31
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_26:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_26]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__runtimearr__struct_5:%[0-9a-zA-Z_]+]] ArrayStride 512
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_10]] Block
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_19]] Binding 1
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_20]] Binding 0
// CHECK:  OpDecorate [[__arr_float_uint_128:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_uint_128:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 128
// CHECK:  [[__arr_float_uint_128]] = OpTypeArray [[_float]] [[_uint_128]]
// CHECK:  [[__struct_5]] = OpTypeStruct [[__arr_float_uint_128]]
// CHECK:  [[__runtimearr__struct_5]] = OpTypeRuntimeArray [[__struct_5]]
// CHECK:  [[__struct_7]] = OpTypeStruct [[__runtimearr__struct_5]]
// CHECK:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_10]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK:  [[_16:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_float]] [[__ptr_StorageBuffer__struct_5]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK:  [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpFunction [[_float]] Pure [[_16]]
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer__struct_5]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_19]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_5]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_24]]
// CHECK:  OpReturnValue [[_25]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_26]] = OpFunction [[_void]] None [[_13]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_20]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_5]] [[_19]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_21]] [[_29]]
// CHECK:  OpStore [[_28]] [[_30]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
