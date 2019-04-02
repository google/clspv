// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv



void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  a[get_num_groups(b)] = get_num_groups(3);
}

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 35
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_21:%[0-9a-zA-Z_]+]] "foo" [[_gl_NumWorkGroups:%[0-9a-zA-Z_]+]]
// CHECK:  OpExecutionMode [[_21]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpDecorate [[_gl_NumWorkGroups]] BuiltIn NumWorkgroups
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_19]] Binding 0
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_20]] Binding 1
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[__struct_5]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_8:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_10:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_uint]] [[_uint]]
// CHECK:  [[_bool:%[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Input_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_v3uint]]
// CHECK:  [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_gl_NumWorkGroups]] = OpVariable [[__ptr_Input_v3uint]] Input
// CHECK:  [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_21]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_20]] [[_uint_0]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_23]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_uint]] [[_27:%[0-9a-zA-Z_]+]] [[_24]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_25]]
// CHECK:  OpStore [[_26]] [[_uint_1]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_27]] = OpFunction [[_uint]] Const [[_10]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpULessThan [[_bool]] [[_28]] [[_uint_3]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_30]] [[_28]] [[_uint_0]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_NumWorkGroups]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_30]] [[_33]] [[_uint_1]]
// CHECK:  OpReturnValue [[_34]]
// CHECK:  OpFunctionEnd
