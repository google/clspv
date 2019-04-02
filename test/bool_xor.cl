// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv






void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int *out, int m, int n)
{
  bool a = m < 100;
  bool b = n > 50;
  if (a ^ b)
  {
    *out = 1;
  }
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 30
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_18:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_18]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpDecorate [[_15:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_15]] Binding 0
// CHECK:  OpDecorate [[_16:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_16]] Binding 1
// CHECK:  OpDecorate [[_17:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_17]] Binding 2
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[__struct_5]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_8:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_bool:%[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_100:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 100
// CHECK:  [[_uint_50:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 50
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_15]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_16]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_17]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_18]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_19:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_20:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_15]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_16]] [[_uint_0]]
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_21]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_17]] [[_uint_0]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_23]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpSLessThan [[_bool]] [[_22]] [[_uint_100]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpSGreaterThan [[_bool]] [[_24]] [[_uint_50]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpLogicalNotEqual [[_bool]] [[_25]] [[_26]]
// CHECK:  OpSelectionMerge [[_29:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_27]] [[_28:%[0-9a-zA-Z_]+]] [[_29]]
// CHECK:  [[_28]] = OpLabel
// CHECK:  OpStore [[_20]] [[_uint_1]]
// CHECK:  OpBranch [[_29]]
// CHECK:  [[_29]] = OpLabel
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
