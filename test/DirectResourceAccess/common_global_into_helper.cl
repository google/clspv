// RUN: clspv %s -o %t.spv -descriptormap=%t.map
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv



//      MAP: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,n,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod,argSize,4
// MAP-NEXT: kernel,bar,arg,B,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,bar,arg,m,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod,argSize,4
// MAP-NONE: kernel



float core(global float *arr, int n) {
  return arr[n];
}

float apple(global float *arr, int n) {
  return core(arr, n) + core(arr, n+1);
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* A, int n)
{
  A[0] = apple(A, n);
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) bar(global float* B, uint m)
{
  B[0] = apple(B, m) + apple(B, m+2);
}

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 48
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_33:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_39:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpExecutionMode [[_33]] LocalSize 1 1 1
// CHECK:  OpExecutionMode [[_39]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_6]] Block
// CHECK:  OpDecorate [[_16:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_16]] Binding 0
// CHECK:  OpDecorate [[_17:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_17]] Binding 1
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__struct_6]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_9:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_float]] [[__ptr_StorageBuffer_float]] [[_uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_16]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_17]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_18:%[0-9a-zA-Z_]+]] = OpFunction [[_float]] Pure [[_12]]
// CHECK:  [[_19:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_float]]
// CHECK:  [[_20:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_16]] [[_uint_0]] [[_20]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_22]]
// CHECK:  OpReturnValue [[_23]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpFunction [[_float]] Pure [[_12]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_float]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_16]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_18]] [[_28]] [[_26]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_26]] [[_uint_1]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_18]] [[_28]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_29]] [[_31]]
// CHECK:  OpReturnValue [[_32]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_33]] = OpFunction [[_void]] None [[_9]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_16]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_17]] [[_uint_0]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_24]] [[_35]] [[_37]]
// CHECK:  OpStore [[_35]] [[_38]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_39]] = OpFunction [[_void]] None [[_9]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_16]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_17]] [[_uint_0]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_42]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_24]] [[_41]] [[_43]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_43]] [[_uint_2]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_24]] [[_41]] [[_45]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_44]] [[_46]]
// CHECK:  OpStore [[_41]] [[_47]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
