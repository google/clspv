// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float2 *A, float2 x, float2 y) {
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
// CHECK: OpDecorate [[__runtimearr_v2float:%[a-zA-Z0-9_]+]] ArrayStride 8
// CHECK: OpMemberDecorate [[__struct_5:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_5]] Block
// CHECK: OpMemberDecorate [[__struct_7:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_7]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_20:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_20]] Binding 0
// CHECK: OpDecorate [[_21:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_21]] Binding 1
// CHECK: OpDecorate [[_22:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_22]] Binding 2
// CHECK: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[_v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 2
// CHECK: [[__ptr_StorageBuffer_v2float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK: [[__runtimearr_v2float]] = OpTypeRuntimeArray [[_v2float]]
// CHECK: [[__struct_5]] = OpTypeStruct [[__runtimearr_v2float]]
// CHECK: [[__ptr_StorageBuffer__struct_5:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK: [[__struct_7]] = OpTypeStruct [[_v2float]]
// CHECK: [[__ptr_StorageBuffer__struct_7:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[_11:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_15]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_16]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_17]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_15]] [[_16]] [[_17]]
// CHECK: [[_19:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK: [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK: [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK: [[_23]] = OpFunction [[_void]] None [[_11]]
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_20]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_21]] [[_uint_0]]
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpLoad [[_v2float]] [[_26]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_22]] [[_uint_0]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpLoad [[_v2float]] [[_28]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpFRem [[_v2float]] [[_27]] [[_29]]
// CHECK: OpStore [[_25]] [[_30]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
