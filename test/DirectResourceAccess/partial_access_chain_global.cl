// RUN: clspv %s -o %t.spv -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Kernel |bar| does a non-trivial access chain before calling the helper.

void apple(global int *A, global int *B, int n) { A[n] = B[n + 2]; }

kernel void foo(global int *A, global int *B, int n) { apple(A, B, n); }

kernel void bar(global int *A, global int *B, int n) { apple(A + 1, B, n); }
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 47
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_33:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_40:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_16:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_17:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_18:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_21]] Binding 1
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 0
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 2
// CHECK:  OpDecorate [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK-DAG:  [[__struct_3]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK-DAG:  [[__struct_5]] = OpTypeStruct [[_uint]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[__ptr_StorageBuffer_uint]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG:  [[_10:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[__ptr_StorageBuffer_uint]] [[__ptr_StorageBuffer_uint]] [[_uint]]
// CHECK:  [[_8:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG:  [[_16]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[_17]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[_18]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_16]] [[_17]] [[_18]]
// CHECK-DAG:  [[_20:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK-DAG:  [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK-DAG:  [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK-DAG:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_10]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_27]] [[_uint_2]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_21]] [[_uint_0]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_StorageBuffer_uint]] [[_25]] [[_27]]
// CHECK:  OpStore [[_32]] [[_31]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_33]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_22]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_21]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_23]] [[_uint_0]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_37]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_24]] [[_35]] [[_36]] [[_38]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_40]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_21]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_23]] [[_uint_0]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_43]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_22]] [[_uint_0]] [[_uint_1]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_24]] [[_45]] [[_42]] [[_44]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
