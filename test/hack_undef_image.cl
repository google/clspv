// Test the -hack-undef option, with an undef image value.
// We must keep the undef image value.
// See https://github.com/google/clspv/issues/95

// RUN: clspv %s -S -o %t.spvasm -hack-undef -no-inline-single -keep-unused-arguments
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -hack-undef -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// This function takes an image argument but does not use it.
// The optimizer is smart enough to have the call pass an undef
// image operand.
float2 bar(float2 coord, read_only image2d_t im) {
  return coord + (float2)(2.5, 2.5);
}

void kernel foo(global float4* A, read_only image2d_t im, sampler_t sam, float2 coord)
{
  *A = read_imagef(im, sam, bar(coord, im));
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 51
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_41:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_27:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_28:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_29:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4float:%[a-zA-Z0-9_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_5:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_5]] Block
// CHECK: OpMemberDecorate [[__struct_12:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_12]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_32:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_32]] Binding 0
// CHECK: OpDecorate [[_33:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_33]] Binding 1
// CHECK: OpDecorate [[_34:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_34]] Binding 2
// CHECK: OpDecorate [[_35:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_35]] Binding 3
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG: [[__struct_5]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_5:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG: [[_7:%[a-zA-Z0-9_]+]] = OpTypeImage [[_float]] 2D 0 0 0 1 Unknown
// CHECK-DAG: [[__ptr_UniformConstant_7:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[_7]]
// CHECK-DAG: [[_9:%[a-zA-Z0-9_]+]] = OpTypeSampler
// CHECK-DAG: [[__ptr_UniformConstant_9:%[a-zA-Z0-9_]+]] = OpTypePointer UniformConstant [[_9]]
// CHECK-DAG: [[_v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[__struct_12]] = OpTypeStruct [[_v2float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_12:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CHECK-DAG: [[__ptr_StorageBuffer_v2float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[_17:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_18:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_v2float]] [[_v2float]] [[_7]]
// CHECK-DAG: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_21:%[a-zA-Z0-9_]+]] = OpTypeSampledImage [[_7]]
// CHECK-DAG: [[_float_0:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0
// CHECK-DAG: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpUndef [[_7]]
// CHECK-DAG: [[_float_2_5:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 2.5
// CHECK-DAG: [[_26:%[a-zA-Z0-9_]+]] = OpConstantComposite [[_v2float]] [[_float_2_5]] [[_float_2_5]]
// CHECK: [[_27]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_28]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_29]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_27]] [[_28]] [[_29]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_32]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK: [[_33]] = OpVariable [[__ptr_UniformConstant_7]] UniformConstant
// CHECK: [[_34]] = OpVariable [[__ptr_UniformConstant_9]] UniformConstant
// CHECK: [[_35]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CHECK: [[_36:%[a-zA-Z0-9_]+]] = OpFunction [[_v2float]] Const [[_18]]
// CHECK: [[_37:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[_v2float]]
// CHECK: [[_38:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[_7]]
// CHECK: [[_39:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_40:%[a-zA-Z0-9_]+]] = OpFAdd [[_v2float]] [[_37]] [[_26]]
// CHECK: OpReturnValue [[_40]]
// CHECK: OpFunctionEnd
// CHECK: [[_41]] = OpFunction [[_void]] None [[_17]]
// CHECK: [[_42:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_43:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_32]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_44:%[a-zA-Z0-9_]+]] = OpLoad [[_7]] [[_33]]
// CHECK: [[_45:%[a-zA-Z0-9_]+]] = OpLoad [[_9]] [[_34]]
// CHECK: [[_46:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_35]] [[_uint_0]]
// CHECK: [[_47:%[a-zA-Z0-9_]+]] = OpLoad [[_v2float]] [[_46]]
// CHECK: [[_48:%[a-zA-Z0-9_]+]] = OpFunctionCall [[_v2float]] [[_36]] [[_47]] [[_24]]
// CHECK: [[_49:%[a-zA-Z0-9_]+]] = OpSampledImage [[_21]] [[_44]] [[_45]]
// CHECK: [[_50:%[a-zA-Z0-9_]+]] = OpImageSampleExplicitLod [[_v4float]] [[_49]] [[_48]] Lod [[_float_0]]
// CHECK: OpStore [[_43]] [[_50]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
