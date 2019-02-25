// RUN: clspv %s -S -o %t.spvasm -no-inline-single -keep-unused-arguments
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

void core(global int *A, int n, constant int *B) { A[n] = B[n + 2]; }

void apple(constant int *B, global int *A, int n) { core(A, n + 1, B); }

kernel void foo(global int *A, int n, constant int *B) { apple(B, A, n); }

kernel void bar(global int *A, int n, constant int *B) { apple(B, A, n); }
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 57
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_43:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_50:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_17:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_18:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 0
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 2
// CHECK:  OpDecorate [[_23]] NonWritable
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_24]] Binding 1
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK-DAG:  [[__struct_3]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK-DAG:  [[__struct_5]] = OpTypeStruct [[_uint]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG:  [[_10:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[__ptr_StorageBuffer_uint]] [[_uint]] [[__ptr_StorageBuffer_uint]]
// CHECK-DAG:  [[_11:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[__ptr_StorageBuffer_uint]] [[__ptr_StorageBuffer_uint]] [[_uint]]
// CHECK:  [[_8:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG:  [[_17]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[_18]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[_19]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_17]] [[_18]] [[_19]]
// CHECK-DAG:  [[_21:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK-DAG:  [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK-DAG:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK-DAG:  [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_10]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_27]] [[_uint_2]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_23]] [[_uint_0]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_22]] [[_uint_0]] [[_27]]
// CHECK:  OpStore [[_33]] [[_32]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_11]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_22]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_1]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_25]] [[_39]] [[_41]] [[_40]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_43]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_22]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_24]] [[_uint_0]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_46]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_34]] [[_48]] [[_45]] [[_47]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_50]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_22]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_24]] [[_uint_0]]
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_53]]
// CHECK:  [[_55:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_56:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_34]] [[_55]] [[_52]] [[_54]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
