// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -no-dra -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm -check-prefix=NODRA
// RUN: spirv-val --target-env vulkan1.0 %t.spv


struct Thing
{
  float a[128];
};


float bar(global struct Thing* a)
{
  return a[1].a[5];
}


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global struct Thing* b)
{
  *a = bar(b);
}

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 32
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_27:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_27]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__runtimearr__struct_5:%[0-9a-zA-Z_]+]] ArrayStride 512
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_10]] Block
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_20]] Binding 1
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_21]] Binding 0
// CHECK:  OpDecorate [[__arr_float_uint_128:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_uint_128:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 128
// CHECK-DAG:  [[__arr_float_uint_128]] = OpTypeArray [[_float]] [[_uint_128]]
// CHECK-DAG:  [[__struct_5]] = OpTypeStruct [[__arr_float_uint_128]]
// CHECK-DAG:  [[__runtimearr__struct_5]] = OpTypeRuntimeArray [[__struct_5]]
// CHECK-DAG:  [[__struct_7]] = OpTypeStruct [[__runtimearr__struct_5]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK-DAG:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK-DAG:  [[__struct_10]] = OpTypeStruct [[__runtimearr_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG:  [[_16:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_float]] [[__ptr_StorageBuffer__struct_5]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK-DAG:  [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK-DAG:  [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpFunction [[_float]] Pure [[_16]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer__struct_5]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_20]] [[_uint_0]] [[_uint_1]] [[_uint_0]] [[_uint_5]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_25]]
// CHECK:  OpReturnValue [[_26]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_27]] = OpFunction [[_void]] None [[_13]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_21]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_5]] [[_20]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_22]] [[_30]]
// CHECK:  OpStore [[_29]] [[_31]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd



// NODRA:  ; SPIR-V
// NODRA:  ; Version: 1.0
// NODRA:  ; Generator: Codeplay; 0
// NODRA:  ; Bound: 32
// NODRA:  ; Schema: 0
// NODRA:  OpCapability Shader
// NODRA:  OpCapability VariablePointers
// NODRA:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// NODRA:  OpExtension "SPV_KHR_variable_pointers"
// NODRA:  OpMemoryModel Logical GLSL450
// NODRA:  OpEntryPoint GLCompute [[_27:%[0-9a-zA-Z_]+]] "foo"
// NODRA:  OpExecutionMode [[_27]] LocalSize 1 1 1
// NODRA:  OpSource OpenCL_C 120
// NODRA:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// NODRA:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// NODRA:  OpDecorate [[__struct_3]] Block
// NODRA:  OpMemberDecorate [[__struct_8:%[0-9a-zA-Z_]+]] 0 Offset 0
// NODRA:  OpDecorate [[__runtimearr__struct_8:%[0-9a-zA-Z_]+]] ArrayStride 512
// NODRA:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// NODRA:  OpDecorate [[__struct_10]] Block
// NODRA:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// NODRA:  OpDecorate [[_20]] Binding 0
// NODRA:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// NODRA:  OpDecorate [[_21]] Binding 1
// NODRA:  OpDecorate [[__arr_float_uint_128:%[0-9a-zA-Z_]+]] ArrayStride 4
// NODRA:  OpDecorate [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// NODRA-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// NODRA-DAG:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// NODRA-DAG:  [[__struct_3]] = OpTypeStruct [[__runtimearr_float]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// NODRA-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// NODRA-DAG:  [[_uint_128:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 128
// NODRA-DAG:  [[__arr_float_uint_128]] = OpTypeArray [[_float]] [[_uint_128]]
// NODRA-DAG:  [[__struct_8]] = OpTypeStruct [[__arr_float_uint_128]]
// NODRA-DAG:  [[__runtimearr__struct_8]] = OpTypeRuntimeArray [[__struct_8]]
// NODRA-DAG:  [[__struct_10]] = OpTypeStruct [[__runtimearr__struct_8]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// NODRA-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// NODRA-DAG:  [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// NODRA-DAG:  [[__ptr_StorageBuffer_float]] = OpTypePointer StorageBuffer [[_float]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_8:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_8]]
// NODRA-DAG:  [[_16:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_float]] [[__ptr_StorageBuffer__struct_8]]
// NODRA:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// NODRA-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// NODRA-DAG:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// NODRA:  [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// NODRA:  [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// NODRA:  [[_22:%[0-9a-zA-Z_]+]] = OpFunction [[_float]] Pure [[_16]]
// NODRA:  [[_23:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer__struct_8]]
// NODRA:  [[_24:%[0-9a-zA-Z_]+]] = OpLabel
// NODRA:  [[_25:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_1]] [[_uint_0]] [[_uint_5]]
// NODRA:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_25]]
// NODRA:  OpReturnValue [[_26]]
// NODRA:  OpFunctionEnd
// NODRA:  [[_27]] = OpFunction [[_void]] None [[_13]]
// NODRA:  [[_28:%[0-9a-zA-Z_]+]] = OpLabel
// NODRA:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_20]] [[_uint_0]] [[_uint_0]]
// NODRA:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_8]] [[_21]] [[_uint_0]] [[_uint_0]]
// NODRA:  [[_31:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_22]] [[_30]]
// NODRA:  OpStore [[_29]] [[_31]]
// NODRA:  OpReturn
// NODRA:  OpFunctionEnd
