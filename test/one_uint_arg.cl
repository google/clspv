// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(uint a)
{
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 13
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_9:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_9]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpMemberDecorate [[__struct_2:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_2]] Block
// CHECK:  OpDecorate [[_8:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_8]] Binding 0
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__struct_2]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_2:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_2]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_5:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_8]] = OpVariable [[__ptr_StorageBuffer__struct_2]] StorageBuffer
// CHECK:  [[_9]] = OpFunction [[_void]] Const [[_5]]
// CHECK:  [[_10:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_11:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_8]] [[_uint_0]]
// CHECK:  [[_12:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_11]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
