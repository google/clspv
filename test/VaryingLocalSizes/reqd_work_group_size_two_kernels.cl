// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


void kernel __attribute__((reqd_work_group_size(42, 13, 5))) foo(global uint* a)
{
  a[0] = get_local_size(0);
  a[1] = get_local_size(1);
  a[2] = get_local_size(2);
  a[3] = get_local_size(3);
}

void kernel __attribute__((reqd_work_group_size(42, 13, 5))) bar(global uint* a)
{
  a[0] = get_local_size(0);
  a[1] = get_local_size(1);
  a[2] = get_local_size(2);
  a[3] = get_local_size(3);
}

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 44
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_20:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_32:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpExecutionMode [[_20]] LocalSize 42 13 5
// CHECK:  OpExecutionMode [[_32]] LocalSize 42 13 5
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_19]] Binding 0
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_6:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 42
// CHECK:  [[_uint_13:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 13
// CHECK:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_gl_WorkGroupSize]] = OpConstantComposite [[_v3uint]] [[_uint_42]] [[_uint_13]] [[_uint_5]]
// CHECK:  [[_18:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_20]] = OpFunction [[_void]] None [[_6]]
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_23]] 0
// CHECK:  OpStore [[_22]] [[_24]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_25]] 1
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_1]]
// CHECK:  OpStore [[_27]] [[_26]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_28]] 2
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_2]]
// CHECK:  OpStore [[_30]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_3]]
// CHECK:  OpStore [[_31]] [[_uint_1]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_32]] = OpFunction [[_void]] None [[_6]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_35]] 0
// CHECK:  OpStore [[_34]] [[_36]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_37]] 1
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_1]]
// CHECK:  OpStore [[_39]] [[_38]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_40]] 2
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_2]]
// CHECK:  OpStore [[_42]] [[_41]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_3]]
// CHECK:  OpStore [[_43]] [[_uint_1]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
