// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(constant uint* a, global uint* b)
{
 *b = *a;
}


// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 17
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_12:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpExecutionMode [[_12]] LocalSize 1 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_uint:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpDecorate [[__runtimearr_uint_0:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpDecorate [[_10:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_10]] Binding 0
// CHECK: OpDecorate [[_10]] NonWritable
// CHECK: OpDecorate [[_11:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_11]] Binding 1
// CHECK: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[__ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK: [[__struct_4]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[_7:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK: [[__runtimearr_uint_0]] = OpTypeRuntimeArray [[_uint]]
// CHECK: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_10]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_11]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_12]] = OpFunction [[_void]] None [[_7]]
// CHECK: [[_13:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_14:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_10]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_15:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_11]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_16:%[a-zA-Z0-9_]+]] = OpLoad [[_uint]] [[_14]]
// CHECK: OpStore [[_15]] [[_16]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
