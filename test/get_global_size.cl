// RUN: clspv %s -S -o %t.spvasm -no-inline-single
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv



void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  a[get_global_size(b)] = get_global_size(3);
}

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 42
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_25:%[0-9a-zA-Z_]+]] "foo" [[_gl_NumWorkGroups:%[0-9a-zA-Z_]+]]
// CHECK:  OpExecutionMode [[_25]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_gl_NumWorkGroups]] BuiltIn NumWorkgroups
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 0
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_24]] Binding 1
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
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[__ptr_Private_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_uint]]
// CHECK:  [[__ptr_Input_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_v3uint]]
// CHECK:  [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_uint]]
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_gl_WorkGroupSize]] = OpConstantComposite [[_v3uint]] [[_uint_1]] [[_uint_1]] [[_uint_1]]
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_gl_NumWorkGroups]] = OpVariable [[__ptr_Input_v3uint]] Input
// CHECK:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_25]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_24]] [[_uint_0]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_27]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_uint]] [[_31:%[0-9a-zA-Z_]+]] [[_28]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_23]] [[_uint_0]] [[_29]]
// CHECK:  OpStore [[_30]] [[_uint_1]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_31]] = OpFunction [[_uint]] Const [[_10]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpULessThan [[_bool]] [[_32]] [[_uint_3]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_34]] [[_32]] [[_uint_0]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Private_uint]] [[_21]] [[_35]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_NumWorkGroups]] [[_35]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_38]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_39]] [[_37]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_34]] [[_40]] [[_uint_1]]
// CHECK:  OpReturnValue [[_41]]
// CHECK:  OpFunctionEnd
