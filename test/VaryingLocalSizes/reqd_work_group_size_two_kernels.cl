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

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 44
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_20:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpEntryPoint GLCompute [[_32:%[a-zA-Z0-9_]+]] "bar"
// CHECK: OpExecutionMode [[_20]] LocalSize 42 13 5
// CHECK: OpExecutionMode [[_32]] LocalSize 42 13 5
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_uint:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_19:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_19]] Binding 0
// CHECK: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[__ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK: [[__struct_4]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[_7:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_uint_42:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 42
// CHECK: [[_uint_13:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 13
// CHECK: [[_uint_5:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 5
// CHECK: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 2
// CHECK: [[_uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 3
// CHECK: [[_gl_WorkGroupSize]] = OpConstantComposite [[_v3uint]] [[_uint_42]] [[_uint_13]] [[_uint_5]]
// CHECK: [[_18:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_20]] = OpFunction [[_void]] None [[_7]]
// CHECK: [[_21:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_22:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_23:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_23]] 0
// CHECK: OpStore [[_22]] [[_24]]
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_25]] 1
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_27]] [[_26]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_28]] 2
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_2]]
// CHECK: OpStore [[_30]] [[_29]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_3]]
// CHECK: OpStore [[_31]] [[_uint_1]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
// CHECK: [[_32]] = OpFunction [[_void]] None [[_7]]
// CHECK: [[_33:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_34:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_35:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_36:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_35]] 0
// CHECK: OpStore [[_34]] [[_36]]
// CHECK: [[_37:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_38:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_37]] 1
// CHECK: [[_39:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_39]] [[_38]]
// CHECK: [[_40:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_41:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_40]] 2
// CHECK: [[_42:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_2]]
// CHECK: OpStore [[_42]] [[_41]]
// CHECK: [[_43:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]] [[_uint_3]]
// CHECK: OpStore [[_43]] [[_uint_1]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
