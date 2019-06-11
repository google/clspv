// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short* a, global short* b)
{
  *a += *b;
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Bound: 19
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability Int16
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_12:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_12]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_ushort:%[0-9a-zA-Z_]+]] ArrayStride 2
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpDecorate [[_10:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_10]] Binding 0
// CHECK:  OpDecorate [[_11:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_11]] Binding 1
// CHECK:  [[_ushort:%[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK:  [[__runtimearr_ushort]] = OpTypeRuntimeArray [[_ushort]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_ushort]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_6:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__ptr_StorageBuffer_ushort:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_ushort]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_10]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_11]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_12]] = OpFunction [[_void]] None [[_6]]
// CHECK:  [[_13:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_14:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_ushort]] [[_10]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_15:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_ushort]] [[_11]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_16:%[0-9a-zA-Z_]+]] = OpLoad [[_ushort]] [[_15]]
// CHECK:  [[_17:%[0-9a-zA-Z_]+]] = OpLoad [[_ushort]] [[_14]]
// CHECK:  [[_18:%[0-9a-zA-Z_]+]] = OpIAdd [[_ushort]] [[_17]] [[_16]]
// CHECK:  OpStore [[_14]] [[_18]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
