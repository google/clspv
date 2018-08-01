// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// This case exercises a fix.

// The A object is complex at the kernel interface.
// But we pass down the first of the firs element of A into helper functions.
// We can still rewrite this as a direct resource access.  We have to count
// the number of GEP zeroes correctly.

typedef struct {
  int arr[12];
} S;


void core(global int *A, int n, global int *B) { A[n] = B[n + 2]; }

void apple(global int *B, global int *A, int n) { core(A, n + 1, B); }

kernel void foo(global S *A, int n, global int *B) { apple(B, &(A->arr[0]), n); }

kernel void bar(global S *A, int n, global int *B) { apple(B, A->arr, n); }


// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 63
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_49:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_56:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_25:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__runtimearr__struct_4:%[0-9a-zA-Z_]+]] ArrayStride 48
// CHECK:  OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_6]] Block
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_9]] Block
// CHECK:  OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_11]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_28]] Binding 0
// CHECK:  OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_29]] Binding 2
// CHECK:  OpDecorate [[_30:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_30]] Binding 1
// CHECK:  OpDecorate [[__arr_uint_uint_12:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_12:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 12
// CHECK:  [[__arr_uint_uint_12]] = OpTypeArray [[_uint]] [[_uint_12]]
// CHECK:  [[__struct_4]] = OpTypeStruct [[__arr_uint_uint_12]]
// CHECK:  [[__runtimearr__struct_4]] = OpTypeRuntimeArray [[__struct_4]]
// CHECK:  [[__struct_6]] = OpTypeStruct [[__runtimearr__struct_4]]
// CHECK:  [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_9]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK:  [[__struct_11]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_14:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_16:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[__ptr_StorageBuffer_uint]] [[_uint]] [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_17:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[__ptr_StorageBuffer_uint]] [[__ptr_StorageBuffer_uint]] [[_uint]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_25]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_23]] [[_24]] [[_25]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_16]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_33]] [[_uint_2]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_29]] [[_uint_0]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_37]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_28]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_33]]
// CHECK:  OpStore [[_39]] [[_38]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_17]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_28]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_29]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_43]] [[_uint_1]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_31]] [[_45]] [[_47]] [[_46]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_49]] = OpFunction [[_void]] None [[_14]]
// CHECK:  [[_50:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_30]] [[_uint_0]]
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_51]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_29]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_28]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_55:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_40]] [[_53]] [[_54]] [[_52]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_56]] = OpFunction [[_void]] None [[_14]]
// CHECK:  [[_57:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_58:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_30]] [[_uint_0]]
// CHECK:  [[_59:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_58]]
// CHECK:  [[_60:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_29]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_61:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_28]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_62:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_40]] [[_60]] [[_61]] [[_59]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
