// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -no-dra -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm -check-prefix=NODRA
// RUN: spirv-val --target-env vulkan1.0 %t.spv



typedef struct {
  float x[12];
} Thing;

float bar(global Thing* a, int n) {
  return a[n].x[7];
}


void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
foo(global Thing* a, global float *b, int n) {
  *b = bar(a, n);
}

// Direct-resource-access optimization converts to straight OpAccessChain

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 38
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_31:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_31]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__runtimearr__struct_5:%[0-9a-zA-Z_]+]] ArrayStride 48
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_10]] Block
// CHECK:  OpMemberDecorate [[__struct_12:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_12]] Block
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 0
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 1
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_24]] Binding 2
// CHECK:  OpDecorate [[__arr_float_uint_12:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_uint_12:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 12
// CHECK-DAG:  [[__arr_float_uint_12]] = OpTypeArray [[_float]] [[_uint_12]]
// CHECK-DAG:  [[__struct_5]] = OpTypeStruct [[__arr_float_uint_12]]
// CHECK-DAG:  [[__runtimearr__struct_5]] = OpTypeRuntimeArray [[__struct_5]]
// CHECK-DAG:  [[__struct_7]] = OpTypeStruct [[__runtimearr__struct_5]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK-DAG:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK-DAG:  [[__struct_10]] = OpTypeStruct [[__runtimearr_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK-DAG:  [[__struct_12]] = OpTypeStruct [[_uint]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_12:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG:  [[_19:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_float]] [[__ptr_StorageBuffer__struct_5]] [[_uint]]
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_15:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_uint_7:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 7
// CHECK:  [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK:  [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunction [[_float]] Pure [[_19]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer__struct_5]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_22]] [[_uint_0]] [[_27]] [[_uint_0]] [[_uint_7]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_29]]
// CHECK:  OpReturnValue [[_30]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_31]] = OpFunction [[_void]] None [[_15]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_5]] [[_22]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_24]] [[_uint_0]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_35]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_25]] [[_33]] [[_36]]
// CHECK:  OpStore [[_34]] [[_37]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd



// NODRA:  ; SPIR-V
// NODRA:  ; Version: 1.0
// NODRA:  ; Generator: Codeplay; 0
// NODRA:  ; Bound: 38
// NODRA:  ; Schema: 0
// NODRA:  OpCapability Shader
// NODRA:  OpCapability VariablePointers
// NODRA:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// NODRA:  OpExtension "SPV_KHR_variable_pointers"
// NODRA:  OpMemoryModel Logical GLSL450
// NODRA:  OpEntryPoint GLCompute [[_31:%[0-9a-zA-Z_]+]] "foo"
// NODRA:  OpExecutionMode [[_31]] LocalSize 1 1 1
// NODRA:  OpSource OpenCL_C 120
// NODRA:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// NODRA:  OpDecorate [[__runtimearr__struct_5:%[0-9a-zA-Z_]+]] ArrayStride 48
// NODRA:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// NODRA:  OpDecorate [[__struct_7]] Block
// NODRA:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// NODRA:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// NODRA:  OpDecorate [[__struct_10]] Block
// NODRA:  OpMemberDecorate [[__struct_12:%[0-9a-zA-Z_]+]] 0 Offset 0
// NODRA:  OpDecorate [[__struct_12]] Block
// NODRA:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// NODRA:  OpDecorate [[_22]] Binding 0
// NODRA:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// NODRA:  OpDecorate [[_23]] Binding 1
// NODRA:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] DescriptorSet 0
// NODRA:  OpDecorate [[_24]] Binding 2
// NODRA:  OpDecorate [[__arr_float_uint_12:%[0-9a-zA-Z_]+]] ArrayStride 4
// NODRA:  OpDecorate [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// NODRA-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// NODRA-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// NODRA-DAG:  [[_uint_12:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 12
// NODRA-DAG:  [[__arr_float_uint_12]] = OpTypeArray [[_float]] [[_uint_12]]
// NODRA-DAG:  [[__struct_5]] = OpTypeStruct [[__arr_float_uint_12]]
// NODRA-DAG:  [[__runtimearr__struct_5]] = OpTypeRuntimeArray [[__struct_5]]
// NODRA-DAG:  [[__struct_7]] = OpTypeStruct [[__runtimearr__struct_5]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// NODRA-DAG:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// NODRA-DAG:  [[__struct_10]] = OpTypeStruct [[__runtimearr_float]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// NODRA-DAG:  [[__struct_12]] = OpTypeStruct [[_uint]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_12:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// NODRA-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// NODRA-DAG:  [[_15:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// NODRA-DAG:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// NODRA-DAG:  [[__ptr_StorageBuffer_float]] = OpTypePointer StorageBuffer [[_float]]
// NODRA-DAG:  [[_19:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_float]] [[__ptr_StorageBuffer__struct_5]] [[_uint]]
// NODRA:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// NODRA-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// NODRA-DAG:  [[_uint_7:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 7
// NODRA:  [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// NODRA:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// NODRA:  [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// NODRA:  [[_25:%[0-9a-zA-Z_]+]] = OpFunction [[_float]] Pure [[_19]]
// NODRA:  [[_26:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer__struct_5]]
// NODRA:  [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// NODRA:  [[_28:%[0-9a-zA-Z_]+]] = OpLabel
// NODRA:  [[_29:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_27]] [[_uint_0]] [[_uint_7]]
// NODRA:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_29]]
// NODRA:  OpReturnValue [[_30]]
// NODRA:  OpFunctionEnd
// NODRA:  [[_31]] = OpFunction [[_void]] None [[_15]]
// NODRA:  [[_32:%[0-9a-zA-Z_]+]] = OpLabel
// NODRA:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_5]] [[_22]] [[_uint_0]] [[_uint_0]]
// NODRA:  [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_23]] [[_uint_0]] [[_uint_0]]
// NODRA:  [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_24]] [[_uint_0]]
// NODRA:  [[_36:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_35]]
// NODRA:  [[_37:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_25]] [[_33]] [[_36]]
// NODRA:  OpStore [[_34]] [[_37]]
// NODRA:  OpReturn
// NODRA:  OpFunctionEnd
