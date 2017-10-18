// Test the -hack-undef option.
// It's a workaround for https://github.com/google/clspv/issues/95

// RUN: clspv %s -S -o %t.spvasm -hack-undef
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -hack-undef
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float4* A)
{
  float4 value;
  value.w = 1111.0f;
  *A = value;
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 25
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_22:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_16:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_17:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_18:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4float:%[a-zA-Z0-9_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_5:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_5]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_21:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_21]] Binding 0
// CHECK: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CHECK: [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK: [[__struct_5]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK: [[__ptr_StorageBuffer__struct_5:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[_9:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_13:%[a-zA-Z0-9_]+]] = OpConstantNull [[_float]]
// CHECK: [[_float_1111:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 1111
// CHECK: [[_15:%[a-zA-Z0-9_]+]] = OpConstantComposite [[_v4float]] [[_13]] [[_13]] [[_13]] [[_float_1111]]
// CHECK: [[_16]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_17]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_18]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_16]] [[_17]] [[_18]]
// CHECK: [[_20:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK: [[_22]] = OpFunction [[_void]] None [[_9]]
// CHECK: [[_23:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_21]] [[_uint_0]] [[_uint_0]]
// CHECK: OpStore [[_24]] [[_15]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
