// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv




constant uint b[4] = {42, 13, 0, 5};






void kernel __attribute__((reqd_work_group_size(4, 1, 1))) foo(global uint* a)
{
  *a = b[get_local_id(0)];
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 30
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_23:%[0-9a-zA-Z_]+]] "foo" [[_gl_LocalInvocationID:%[0-9a-zA-Z_]+]]
// CHECK:  OpExecutionMode [[_23]] LocalSize 4 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpDecorate [[_gl_LocalInvocationID]] BuiltIn LocalInvocationId
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 0
// CHECK:  OpDecorate [[__arr_uint_uint_4:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_6:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Input_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_v3uint]]
// CHECK:  [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_uint]]
// CHECK:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK:  [[__arr_uint_uint_4]] = OpTypeArray [[_uint]] [[_uint_4]]
// CHECK:  [[__ptr_Private__arr_uint_uint_4:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[__arr_uint_uint_4]]
// CHECK:  [[__ptr_Private_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 42
// CHECK:  [[_uint_13:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 13
// CHECK:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK:  [[_19:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__arr_uint_uint_4]] [[_uint_42]] [[_uint_13]] [[_uint_0]] [[_uint_5]]
// CHECK:  [[_gl_LocalInvocationID]] = OpVariable [[__ptr_Input_v3uint]] Input
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private__arr_uint_uint_4]] Private [[_19]]
// CHECK:  [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_23]] = OpFunction [[_void]] None [[_6]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_22]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_LocalInvocationID]] [[_uint_0]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_26]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Private_uint]] [[_21]] [[_27]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_28]]
// CHECK:  OpStore [[_25]] [[_29]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
