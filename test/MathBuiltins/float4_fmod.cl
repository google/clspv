// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float4 *A, float4 x, float4 y) {
  *A = fmod(x,y);
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 31
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_23:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_15:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_16:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_17:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4float:%[a-zA-Z0-9_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_5:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_5:%[a-zA-Z0-9_]+]] Block
// CHECK: OpMemberDecorate [[__struct_7:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_7:%[a-zA-Z0-9_]+]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_20:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_20:%[a-zA-Z0-9_]+]] Binding 0
// CHECK: OpDecorate [[_21:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_21:%[a-zA-Z0-9_]+]] Binding 1
// CHECK: OpDecorate [[_22:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_22:%[a-zA-Z0-9_]+]] Binding 2
// CHECK: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float:%[a-zA-Z0-9_]+]] 4
// CHECK: [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v4float:%[a-zA-Z0-9_]+]]
// CHECK: [[__runtimearr_v4float:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[_v4float:%[a-zA-Z0-9_]+]]
// CHECK: [[__struct_5:%[a-zA-Z0-9_]+]] = OpTypeStruct [[__runtimearr_v4float:%[a-zA-Z0-9_]+]]
// CHECK: [[__ptr_StorageBuffer__struct_5:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_5:%[a-zA-Z0-9_]+]]
// CHECK: [[__struct_7:%[a-zA-Z0-9_]+]] = OpTypeStruct [[_v4float:%[a-zA-Z0-9_]+]]
// CHECK: [[__ptr_StorageBuffer__struct_7:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_7:%[a-zA-Z0-9_]+]]
// CHECK: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[_11:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void:%[a-zA-Z0-9_]+]]
// CHECK: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint:%[a-zA-Z0-9_]+]] 3
// CHECK: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint:%[a-zA-Z0-9_]+]]
// CHECK: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint:%[a-zA-Z0-9_]+]] 0
// CHECK: [[_15:%[a-zA-Z0-9_]+]] = OpSpecConstant [[_uint:%[a-zA-Z0-9_]+]] 1
// CHECK: [[_16:%[a-zA-Z0-9_]+]] = OpSpecConstant [[_uint:%[a-zA-Z0-9_]+]] 1
// CHECK: [[_17:%[a-zA-Z0-9_]+]] = OpSpecConstant [[_uint:%[a-zA-Z0-9_]+]] 1
// CHECK: [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] = OpSpecConstantComposite [[_v3uint:%[a-zA-Z0-9_]+]] [[_15:%[a-zA-Z0-9_]+]] [[_16:%[a-zA-Z0-9_]+]] [[_17:%[a-zA-Z0-9_]+]]
// CHECK: [[_19:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] Private [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]]
// CHECK: [[_20:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_StorageBuffer__struct_5:%[a-zA-Z0-9_]+]] StorageBuffer
// CHECK: [[_21:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_StorageBuffer__struct_7:%[a-zA-Z0-9_]+]] StorageBuffer
// CHECK: [[_22:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_StorageBuffer__struct_7:%[a-zA-Z0-9_]+]] StorageBuffer
// CHECK: [[_23:%[a-zA-Z0-9_]+]] = OpFunction [[_void:%[a-zA-Z0-9_]+]] None [[_11:%[a-zA-Z0-9_]+]]
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] [[_20:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]]
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] [[_21:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]]
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpLoad [[_v4float:%[a-zA-Z0-9_]+]] [[_26:%[a-zA-Z0-9_]+]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] [[_22:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpLoad [[_v4float:%[a-zA-Z0-9_]+]] [[_28:%[a-zA-Z0-9_]+]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpFRem [[_v4float:%[a-zA-Z0-9_]+]] [[_27:%[a-zA-Z0-9_]+]] [[_29:%[a-zA-Z0-9_]+]]
// CHECK: OpStore [[_25:%[a-zA-Z0-9_]+]] [[_30:%[a-zA-Z0-9_]+]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
