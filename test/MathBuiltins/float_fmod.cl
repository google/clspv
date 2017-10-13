// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float *A, float x, float y) {
  *A = fmod(x,y);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 30
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_22:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_14:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_15:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_16:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4:%[a-zA-Z0-9_]+]] Block
// CHECK: OpMemberDecorate [[__struct_6:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6:%[a-zA-Z0-9_]+]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_19:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_19:%[a-zA-Z0-9_]+]] Binding 0
// CHECK: OpDecorate [[_20:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_20:%[a-zA-Z0-9_]+]] Binding 1
// CHECK: OpDecorate [[_21:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_21:%[a-zA-Z0-9_]+]] Binding 2
// CHECK: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float:%[a-zA-Z0-9_]+]]
// CHECK: [[__runtimearr_float:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[_float:%[a-zA-Z0-9_]+]]
// CHECK: [[__struct_4:%[a-zA-Z0-9_]+]] = OpTypeStruct [[__runtimearr_float:%[a-zA-Z0-9_]+]]
// CHECK: [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_4:%[a-zA-Z0-9_]+]]
// CHECK: [[__struct_6:%[a-zA-Z0-9_]+]] = OpTypeStruct [[_float:%[a-zA-Z0-9_]+]]
// CHECK: [[__ptr_StorageBuffer__struct_6:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_6:%[a-zA-Z0-9_]+]]
// CHECK: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[_10:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void:%[a-zA-Z0-9_]+]]
// CHECK: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint:%[a-zA-Z0-9_]+]] 3
// CHECK: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint:%[a-zA-Z0-9_]+]]
// CHECK: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint:%[a-zA-Z0-9_]+]] 0
// CHECK: [[_14:%[a-zA-Z0-9_]+]] = OpSpecConstant [[_uint:%[a-zA-Z0-9_]+]] 1
// CHECK: [[_15:%[a-zA-Z0-9_]+]] = OpSpecConstant [[_uint:%[a-zA-Z0-9_]+]] 1
// CHECK: [[_16:%[a-zA-Z0-9_]+]] = OpSpecConstant [[_uint:%[a-zA-Z0-9_]+]] 1
// CHECK: [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] = OpSpecConstantComposite [[_v3uint:%[a-zA-Z0-9_]+]] [[_14:%[a-zA-Z0-9_]+]] [[_15:%[a-zA-Z0-9_]+]] [[_16:%[a-zA-Z0-9_]+]]
// CHECK: [[_18:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] Private [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]]
// CHECK: [[_19:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] StorageBuffer
// CHECK: [[_20:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_StorageBuffer__struct_6:%[a-zA-Z0-9_]+]] StorageBuffer
// CHECK: [[_21:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_StorageBuffer__struct_6:%[a-zA-Z0-9_]+]] StorageBuffer
// CHECK: [[_22:%[a-zA-Z0-9_]+]] = OpFunction [[_void:%[a-zA-Z0-9_]+]] None [[_10:%[a-zA-Z0-9_]+]]
// CHECK: [[_23:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] [[_19:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]]
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] [[_20:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]]
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpLoad [[_float:%[a-zA-Z0-9_]+]] [[_25:%[a-zA-Z0-9_]+]]
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] [[_21:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpLoad [[_float:%[a-zA-Z0-9_]+]] [[_27:%[a-zA-Z0-9_]+]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpFRem [[_float:%[a-zA-Z0-9_]+]] [[_26:%[a-zA-Z0-9_]+]] [[_28:%[a-zA-Z0-9_]+]]
// CHECK: OpStore [[_24:%[a-zA-Z0-9_]+]] [[_29:%[a-zA-Z0-9_]+]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
